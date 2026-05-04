#Requires -Version 5.1
<#
.SYNOPSIS
    errorOccurred hook - capture error details, log, display friendly message.
.DESCRIPTION
    Executed whenever Copilot encounters an error during tool execution
    or agentic reasoning.
    - Captures error message and stack trace from env vars
    - Appends structured entry to logs/errors.log
    - Categorizes the error (DB, network, file, auth, unknown)
    - Prints a friendly, actionable console message
    - Suggests a retry or manual resolution step
    Exit 0 always (informational hook - cannot change outcome)
#>

$ErrorActionPreference = 'Continue'

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG       = $script:LOG_ERRORS
$sessionId = Get-SessionId
$ts        = Get-Date -Format $script:LOG_DATE_FMT
Ensure-LogsDir

# ── Read error context from Copilot env vars ──────────────────────────────────
# Copilot sets these before invoking errorOccurred:
#   COPILOT_ERROR_MESSAGE  - human-readable error description
#   COPILOT_ERROR_CODE     - numeric or symbolic error code (optional)
#   COPILOT_ERROR_STACK    - stack trace (optional, may be empty)
#   COPILOT_TOOL_NAME      - tool that caused the error (if applicable)
$errorMsg   = if ($env:COPILOT_ERROR_MESSAGE) { $env:COPILOT_ERROR_MESSAGE } else { 'Unknown error (no message provided)' }
$errorCode  = if ($env:COPILOT_ERROR_CODE)    { $env:COPILOT_ERROR_CODE }    else { 'N/A' }
$stackTrace = if ($env:COPILOT_ERROR_STACK)   { $env:COPILOT_ERROR_STACK }   else { '(no stack trace available)' }
$toolName   = if ($env:COPILOT_TOOL_NAME)     { $env:COPILOT_TOOL_NAME }     else { 'N/A' }

# ── Classify the error ────────────────────────────────────────────────────────
$category    = 'UNKNOWN'
$suggestion  = 'Review the full error in logs/errors.log and retry the operation.'

if      ($errorMsg -imatch 'sql|database|db|entity|migration|connection string') {
    $category   = 'DATABASE'
    $suggestion = 'Check your SQL Server connection string in appsettings.json and ensure the DB is running. Try: dotnet ef database update'
} elseif ($errorMsg -imatch 'certificate|ssl|tls|https|self.signed') {
    $category   = 'TLS/CERT'
    $suggestion = 'The API uses a self-signed certificate. Run: dotnet dev-certs https --trust'
} elseif ($errorMsg -imatch '401|403|unauthorized|forbidden|token|auth') {
    $category   = 'AUTH'
    $suggestion = 'Authentication failed. Verify API keys, JWT tokens, or CORS settings.'
} elseif ($errorMsg -imatch 'timeout|connection refused|ECONNREFUSED|host not found') {
    $category   = 'NETWORK'
    $suggestion = "Ensure the API is running at $($script:API_BASE_URL). Run: dotnet run --project ProductCrudApi"
} elseif ($errorMsg -imatch 'file not found|directory|path|access denied|permission') {
    $category   = 'FILESYSTEM'
    $suggestion = 'Check file paths and permissions. Ensure the workspace root is set correctly.'
} elseif ($errorMsg -imatch 'build|compile|msbuild|csc') {
    $category   = 'BUILD'
    $suggestion = 'Resolve compilation errors. Run: dotnet build ProductCrudApi/ProductCrudApi.csproj'
} elseif ($errorMsg -imatch 'test|assert|xunit|nunit') {
    $category   = 'TEST'
    $suggestion = 'Unit tests are failing. Run: dotnet test and fix the failing tests.'
}

# ── Truncate large stack trace ────────────────────────────────────────────────
$stackSnippet = if ($stackTrace.Length -gt 1500) {
    $stackTrace.Substring(0, 1500) + "`n...[truncated - see $LOG for full trace]"
} else {
    $stackTrace
}

# ── Write structured log entry ────────────────────────────────────────────────
$separator = '=' * 60
Add-Content -Path $LOG -Value "`n$separator"                                 -Encoding UTF8
Add-Content -Path $LOG -Value "[$ts] [ERROR] category=$category session=$sessionId" -Encoding UTF8
Add-Content -Path $LOG -Value "  Tool       : $toolName"                     -Encoding UTF8
Add-Content -Path $LOG -Value "  Error Code : $errorCode"                    -Encoding UTF8
Add-Content -Path $LOG -Value "  Message    : $errorMsg"                     -Encoding UTF8
Add-Content -Path $LOG -Value "  Suggestion : $suggestion"                   -Encoding UTF8
Add-Content -Path $LOG -Value '  Stack Trace:'                                -Encoding UTF8
$stackSnippet -split "`n" | ForEach-Object {
    Add-Content -Path $LOG -Value "    $_" -Encoding UTF8
}
Add-Content -Path $LOG -Value $separator                                      -Encoding UTF8

# ── Friendly console banner ───────────────────────────────────────────────────
Write-Host ''
Write-Host ('─' * 70) -ForegroundColor DarkRed
Write-Host "  [errorOccurred] $category ERROR" -ForegroundColor Red
Write-Host ('─' * 70) -ForegroundColor DarkRed
Write-Host "  Tool       : $toolName"           -ForegroundColor White
Write-Host "  Code       : $errorCode"          -ForegroundColor White
Write-Host ''
Write-Host '  What went wrong:' -ForegroundColor Yellow
Write-Host "    $errorMsg" -ForegroundColor White
Write-Host ''
Write-Host '  Suggested action:' -ForegroundColor Cyan
Write-Host "    $suggestion" -ForegroundColor White
Write-Host ''
Write-Host '  Full details logged to: logs/errors.log' -ForegroundColor DarkGray
Write-Host ('─' * 70) -ForegroundColor DarkRed
Write-Host ''

# ── Retry hint for transient errors ───────────────────────────────────────────
if ($category -in @('NETWORK', 'DATABASE', 'TLS/CERT')) {
    Write-Host '  TIP: This error may be transient. You can ask Copilot to "retry the last operation".' -ForegroundColor Magenta
    Write-Host ''
}

# ── Update session metadata with error count ──────────────────────────────────
try {
    $meta = Get-SessionMeta
    if ($meta) {
        $errCount = if ($meta.ErrorCount) { [int]$meta.ErrorCount + 1 } else { 1 }
        Save-SessionMeta @{
            SessionId        = $meta.SessionId
            StartTime        = $meta.StartTime
            WorkDir          = $meta.WorkDir
            FilesChanged     = @($meta.FilesChanged)
            ToolCalls        = [int]$meta.ToolCalls
            DangerousPrompts = if ($meta.DangerousPrompts) { [int]$meta.DangerousPrompts } else { 0 }
            ErrorCount       = $errCount
        }
    }
} catch {
    # Silently ignore metadata errors
}

exit 0
