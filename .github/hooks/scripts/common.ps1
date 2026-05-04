#Requires -Version 5.1
<#
.SYNOPSIS
    Shared utilities for GitHub Copilot lifecycle hook scripts.
.DESCRIPTION
    Provides constants, structured logging, API helpers, smoke-test runner,
    session metadata management, and dangerous-pattern detection.
    Dot-source this file at the top of every hook script:
        . (Join-Path $PSScriptRoot 'common.ps1')
.NOTES
    Project : ProductCrudApi  (.NET 9 Web API)
    Hooks   : GitHub Copilot Agent Lifecycle Hooks
#>

Set-StrictMode -Off   # relax - hook scripts run in varied environments

# Make HTTPS localhost calls work in Windows PowerShell 5.1 where
# -SkipCertificateCheck is not available on web cmdlets.
if ($PSVersionTable.PSVersion.Major -lt 6) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

# ── Constants ─────────────────────────────────────────────────────────────────
$script:API_BASE_URL    = 'https://localhost:5003'
$script:LOGS_DIR        = 'logs'
$script:LOG_DATE_FMT    = 'yyyy-MM-dd HH:mm:ss'

$script:LOG_SESSION     = 'logs/session.log'
$script:LOG_PROMPTS     = 'logs/prompts.log'
$script:LOG_ERRORS      = 'logs/errors.log'
$script:LOG_TOOLS       = 'logs/tools.log'
$script:LOG_AGENT       = 'logs/agent.log'
$script:LOG_SMOKE       = 'logs/smoke-tests.log'
$script:LOG_SUBAGENT    = 'logs/subagent.log'
$script:SESSION_META    = 'logs/.session-meta.json'

$script:CLEANUP_DAYS    = 7         # remove logs older than N days during sessionEnd
$script:MAX_LOG_SIZE_MB = 10        # rotate log if it exceeds this size

# ── Dangerous patterns ────────────────────────────────────────────────────────
$script:DANGEROUS_PROMPT_PATTERNS = @(
    'drop\s+(table|database|db)',
    'delete\s+all',
    'truncate\s+table',
    'delete\s+from\s+\w+\s*(?:where\s+1\s*=\s*1)',
    'remove-item\s+-recurse\s+-force',
    'rm\s+-rf',
    '\bdelete\b.*\ball\b.*\brecords\b',
    'format\s+[a-z]:'
)

$script:DANGEROUS_TOOL_PATTERNS = @(
    'drop\s+database',
    'drop\s+table',
    'truncate\s+table',
    'Delete-SqlDatabase',
    'Remove-Item.*-Recurse.*-Force.*(src|ProductCrudApi|Migrations)',
    'delete\s+from\s+\w+\s*;'
)

# ── API-related file extensions (triggers post-tool smoke test re-run) ─────────
$script:API_FILE_EXTENSIONS = @('.cs', '.csproj', '.json', '.sql', '.ps1')
$script:API_PATH_KEYWORDS   = @('Controllers', 'Services', 'Repositories', 'Models', 'DTOs', 'Migrations')

# ─────────────────────────────────────────────────────────────────────────────
#region Logging
# ─────────────────────────────────────────────────────────────────────────────

function Ensure-LogsDir {
    param([string]$Path = $script:LOGS_DIR)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Rotate-LogIfNeeded {
    param([string]$LogFile)
    if (!(Test-Path $LogFile)) { return }
    $sizeMB = (Get-Item $LogFile).Length / 1MB
    if ($sizeMB -gt $script:MAX_LOG_SIZE_MB) {
        $archive = "$LogFile.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
        Rename-Item -Path $LogFile -NewName (Split-Path $archive -Leaf) -Force
    }
}

function Write-HookLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$LogFile,
        [ValidateSet('INFO','WARN','ERROR','DEBUG','SUCCESS')]
        [string]$Level = 'INFO'
    )
    Ensure-LogsDir
    Rotate-LogIfNeeded -LogFile $LogFile

    $timestamp = Get-Date -Format $script:LOG_DATE_FMT
    $entry     = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -Path $LogFile -Value $entry -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Warning "HookLog: could not write to '$LogFile': $_"
    }

    $color = switch ($Level) {
        'ERROR'   { 'Red' }
        'WARN'    { 'Yellow' }
        'SUCCESS' { 'Green' }
        'DEBUG'   { 'DarkGray' }
        default   { 'Cyan' }
    }
    Write-Host $entry -ForegroundColor $color
}

# Convenience wrappers
function Write-HookInfo    { param([string]$Msg, [string]$Log) Write-HookLog -Message $Msg -LogFile $Log -Level 'INFO'    }
function Write-HookWarn    { param([string]$Msg, [string]$Log) Write-HookLog -Message $Msg -LogFile $Log -Level 'WARN'    }
function Write-HookError   { param([string]$Msg, [string]$Log) Write-HookLog -Message $Msg -LogFile $Log -Level 'ERROR'   }
function Write-HookSuccess { param([string]$Msg, [string]$Log) Write-HookLog -Message $Msg -LogFile $Log -Level 'SUCCESS' }
function Write-HookDebug   { param([string]$Msg, [string]$Log) Write-HookLog -Message $Msg -LogFile $Log -Level 'DEBUG'   }

#endregion

# ─────────────────────────────────────────────────────────────────────────────
#region Session metadata
# ─────────────────────────────────────────────────────────────────────────────

function Get-SessionId {
    if ($env:COPILOT_HOOK_SESSION_ID)  { return $env:COPILOT_HOOK_SESSION_ID  }
    if ($env:COPILOT_AGENT_SESSION_ID) { return $env:COPILOT_AGENT_SESSION_ID }
    return "session-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

function Get-SessionMeta {
    if (Test-Path $script:SESSION_META) {
        try   { return Get-Content $script:SESSION_META -Raw | ConvertFrom-Json }
        catch { return $null }
    }
    return $null
}

function Save-SessionMeta {
    param([hashtable]$Data)
    Ensure-LogsDir
    $Data | ConvertTo-Json -Depth 5 | Set-Content $script:SESSION_META -Encoding UTF8
}

#endregion

# ─────────────────────────────────────────────────────────────────────────────
#region API helpers
# ─────────────────────────────────────────────────────────────────────────────

function Get-HookHttpStatusCode {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [ValidateSet('GET','POST','PUT','PATCH','DELETE')]
        [string]$Method = 'GET',
        [int]$TimeoutSec = 5,
        [string]$Body,
        [string]$ContentType
    )

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $curlArgs = @('-k', '-sS', '-o', 'NUL', '-w', '%{http_code}', '--max-time', "$TimeoutSec", '-X', $Method)
        if ($ContentType) {
            $curlArgs += @('-H', "Content-Type: $ContentType")
        }
        if ($Body) {
            $curlArgs += @('--data-raw', $Body)
        }
        $curlArgs += $Uri

        try {
            $curlOutput = & curl.exe @curlArgs 2>$null
            $curlExitCode = $LASTEXITCODE
        } catch {
            return 0
        }

        if ($curlExitCode -ne 0) {
            return 0
        }

        $status = 0
        [void][int]::TryParse(($curlOutput | Out-String).Trim(), [ref]$status)
        return $status
    }

    try {
        $params = @{
            Uri                  = $Uri
            Method               = $Method
            TimeoutSec           = $TimeoutSec
            SkipCertificateCheck = $true
            ErrorAction          = 'Stop'
        }
        if ($Body) {
            $params.Body = $Body
            if ($ContentType) {
                $params.ContentType = $ContentType
            }
        }

        $resp = Invoke-WebRequest @params
        return [int]$resp.StatusCode
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            return [int]$_.Exception.Response.StatusCode
        }
        return 0
    } catch {
        return 0
    }
}

function Test-ApiHealth {
    [OutputType([bool])]
    param(
        [string]$BaseUrl   = $script:API_BASE_URL,
        [int]   $TimeoutSec = 5
    )
    $BaseUrl = $BaseUrl.TrimEnd('/')
    return ((Get-HookHttpStatusCode -Uri "$BaseUrl/health" -Method GET -TimeoutSec $TimeoutSec) -eq 200)
}

function Test-SwaggerAvailable {
    [OutputType([bool])]
    param(
        [string]$BaseUrl    = $script:API_BASE_URL,
        [int]   $TimeoutSec = 5
    )
    $BaseUrl = $BaseUrl.TrimEnd('/')
    return ((Get-HookHttpStatusCode -Uri "$BaseUrl/swagger/index.html" -Method GET -TimeoutSec $TimeoutSec) -eq 200)
}

function Invoke-SmokeTests {
    [OutputType([bool])]
    param(
        [string]$BaseUrl = $script:API_BASE_URL,
        [string]$LogFile = $script:LOG_SMOKE
    )
    Ensure-LogsDir

    $passed = 0
    $failed = 0

    $tests = @(
        @{ Name = 'GET /health';                    Uri = "$BaseUrl/health";             Method = 'GET';  ExpectedStatus = 200; Body = $null },
        @{ Name = 'GET /swagger/index.html';        Uri = "$BaseUrl/swagger/index.html"; Method = 'GET';  ExpectedStatus = 200; Body = $null },
        @{ Name = 'GET /api/product';               Uri = "$BaseUrl/api/product";        Method = 'GET';  ExpectedStatus = 200; Body = $null },
        @{ Name = 'POST /api/product (malformed)';  Uri = "$BaseUrl/api/product";        Method = 'POST'; ExpectedStatus = 400; Body = '{}' }
    )

    $header = "`n=== Smoke Test Run @ $(Get-Date -Format $script:LOG_DATE_FMT) ==="
    Add-Content -Path $LogFile -Value $header -Encoding UTF8
    Write-Host $header -ForegroundColor Magenta

    foreach ($t in $tests) {
        $status = Get-HookHttpStatusCode `
            -Uri $t.Uri `
            -Method $t.Method `
            -TimeoutSec 10 `
            -Body $t.Body `
            -ContentType 'application/json'

        if ($status -eq $t.ExpectedStatus) {
            $passed++
            $line = "  [PASS] $($t.Name) -> HTTP $status"
            Add-Content -Path $LogFile -Value $line -Encoding UTF8
            Write-Host $line -ForegroundColor Green
        } else {
            $failed++
            $line = "  [FAIL] $($t.Name) -> HTTP $status (expected $($t.ExpectedStatus))"
            Add-Content -Path $LogFile -Value $line -Encoding UTF8
            Write-Host $line -ForegroundColor Red
        }
    }

    $summary = "  Result: $passed passed, $failed failed"
    Add-Content -Path $LogFile -Value $summary -Encoding UTF8
    Write-Host $summary -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })

    return ($failed -eq 0)
}

#endregion

# ─────────────────────────────────────────────────────────────────────────────
#region Safety helpers
# ─────────────────────────────────────────────────────────────────────────────

function Test-DangerousContent {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]  $Content,
        [string[]]                      $Patterns = $script:DANGEROUS_PROMPT_PATTERNS
    )
    foreach ($pattern in $Patterns) {
        if ($Content -imatch $pattern) {
            return @{ Matched = $true; Pattern = $pattern }
        }
    }
    return @{ Matched = $false; Pattern = $null }
}

function Test-ApiFileChange {
    [OutputType([bool])]
    param([string]$FilePath)
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return $false }
    $ext     = [System.IO.Path]::GetExtension($FilePath)
    $hasExt  = $script:API_FILE_EXTENSIONS -contains $ext
    $hasPath = ($script:API_PATH_KEYWORDS | Where-Object { $FilePath -imatch $_ }).Count -gt 0
    return ($hasExt -and $hasPath) -or ($ext -eq '.csproj')
}

#endregion
