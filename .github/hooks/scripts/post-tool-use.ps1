#Requires -Version 5.1
<#
.SYNOPSIS
    postToolUse hook - log tool output, capture execution time, and re-run smoke tests.
.DESCRIPTION
    Executed immediately after every tool call completes.
    - Reads COPILOT_TOOL_START_TIME (set by preToolUse) to compute elapsed ms
    - Logs the tool name, status, and truncated output
    - Flags slow tool calls (> 2 000 ms)
    - If the tool modified an API-related file (.cs, .csproj, etc.),
      re-runs the Product smoke tests automatically
    Exit 0 always (observational hook - never blocks execution)
#>

$ErrorActionPreference = 'Continue'

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG       = $script:LOG_TOOLS
$sessionId = Get-SessionId
$ts        = Get-Date -Format $script:LOG_DATE_FMT
Ensure-LogsDir

# ── Read tool context ─────────────────────────────────────────────────────────
# Copilot sets these before invoking postToolUse:
#   COPILOT_TOOL_NAME    - the tool that just ran
#   COPILOT_TOOL_RESULT  - JSON string with the tool's output
#   COPILOT_TOOL_STATUS  - 'success' | 'error' | 'cancelled'
$toolName   = if ($env:COPILOT_TOOL_NAME)   { $env:COPILOT_TOOL_NAME }   else { 'unknown-tool' }
$toolResult = if ($env:COPILOT_TOOL_RESULT) { $env:COPILOT_TOOL_RESULT } else { '{}' }
$toolStatus = if ($env:COPILOT_TOOL_STATUS) { $env:COPILOT_TOOL_STATUS } else { 'unknown' }

# ── Compute elapsed execution time ────────────────────────────────────────────
$elapsedMs   = $null
$slowWarning = $false

if ($env:COPILOT_TOOL_START_TIME) {
    try {
        $startTime = [datetime]::Parse($env:COPILOT_TOOL_START_TIME)
        $elapsedMs = [int]([datetime]::Now - $startTime).TotalMilliseconds
        if ($elapsedMs -gt 2000) {
            $slowWarning = $true
        }
    } catch {
        Write-HookDebug "Could not parse COPILOT_TOOL_START_TIME: $_" $LOG
    }
}
# Clear start-time env var for the next tool call
$env:COPILOT_TOOL_START_TIME = $null

# ── Truncate output for logging (max 500 chars) ────────────────────────────────
$resultSnippet = if ($toolResult.Length -gt 500) {
    $toolResult.Substring(0, 500) + '...[truncated]'
} else {
    $toolResult
}

# ── Log the tool result ───────────────────────────────────────────────────────
$elapsedStr = if ($null -ne $elapsedMs) { "${elapsedMs}ms" } else { 'n/a' }
$logLine    = "[$ts] [POST-TOOL] tool=$toolName status=$toolStatus elapsed=$elapsedStr session=$sessionId"
Add-Content -Path $LOG -Value $logLine         -Encoding UTF8
Add-Content -Path $LOG -Value "  output: $resultSnippet" -Encoding UTF8

$statusColor = if ($toolStatus -eq 'success') { 'Green' } elseif ($toolStatus -eq 'error') { 'Red' } else { 'Yellow' }
Write-Host "[postToolUse] $toolName | status=$toolStatus | elapsed=$elapsedStr" -ForegroundColor $statusColor

# ── Warn on slow tool calls ───────────────────────────────────────────────────
if ($slowWarning) {
    Write-HookWarn "Slow tool detected: '$toolName' took ${elapsedMs}ms (threshold=2000ms)" $LOG
    Write-Host "[postToolUse] WARNING: slow tool call (${elapsedMs}ms)" -ForegroundColor Yellow
}

# ── Warn on tool errors ───────────────────────────────────────────────────────
if ($toolStatus -eq 'error') {
    Write-HookWarn "Tool '$toolName' reported an error. Review output above." $LOG
}

# ── Detect whether an API-related file was changed ────────────────────────────
# Check common file-write tools for a changed file path
$changedFile = $null
try {
    $params = $toolResult | ConvertFrom-Json -ErrorAction Stop
    # Different tools expose the path under different keys
    $changedFile = if ($params.filePath) { $params.filePath } elseif ($params.path) { $params.path } elseif ($params.file) { $params.file } else { $null }
} catch { }

# Also check tool name directly (e.g., create_file, replace_string_in_file)
if (-not $changedFile -and $toolName -imatch 'file|edit|replace|write|create') {
    try {
        $inputParams = if ($env:COPILOT_TOOL_PARAMETERS) { $env:COPILOT_TOOL_PARAMETERS | ConvertFrom-Json -ErrorAction Stop } else { $null }
        if ($inputParams) {
            $changedFile = if ($inputParams.filePath) { $inputParams.filePath } elseif ($inputParams.path) { $inputParams.path } else { $null }
        }
    } catch { }
}

# ── Track changed file in session metadata ─────────────────────────────────────
if ($changedFile) {
    try {
        $meta = Get-SessionMeta
        if ($meta) {
            $files = [System.Collections.Generic.List[string]]@($meta.FilesChanged)
            if ($changedFile -notin $files) { $files.Add($changedFile) }
            Save-SessionMeta @{
                SessionId        = $meta.SessionId
                StartTime        = $meta.StartTime
                WorkDir          = $meta.WorkDir
                FilesChanged     = $files.ToArray()
                ToolCalls        = [int]$meta.ToolCalls
                DangerousPrompts = if ($meta.DangerousPrompts) { [int]$meta.DangerousPrompts } else { 0 }
            }
        }
    } catch {
        Write-HookDebug "Could not update session metadata: $_" $LOG
    }
}

# ── Re-run smoke tests if an API-related file was modified ────────────────────
if ($changedFile -and (Test-ApiFileChange -FilePath $changedFile)) {
    Write-HookInfo "API-related file changed: $changedFile - re-running smoke tests..." $LOG
    Write-Host "[postToolUse] API file change detected ($changedFile). Re-running smoke tests..." -ForegroundColor Magenta

    if (Test-ApiHealth -BaseUrl $script:API_BASE_URL) {
        $smokeOk = Invoke-SmokeTests -BaseUrl $script:API_BASE_URL
        if ($smokeOk) {
            Write-HookSuccess 'Post-change smoke tests PASSED.' $LOG
        } else {
            Write-HookWarn 'Post-change smoke tests had failures. Review logs/smoke-tests.log.' $LOG
        }
    } else {
        Write-HookWarn 'API not reachable - skipping post-change smoke tests.' $LOG
    }
}

exit 0
