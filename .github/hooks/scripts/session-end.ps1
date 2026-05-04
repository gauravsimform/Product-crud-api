#Requires -Version 5.1
<#
.SYNOPSIS
    sessionEnd hook - cleanup old logs, display session summary.
.DESCRIPTION
    Executed once when the Copilot session ends (user closes chat / extension
    unloads / explicit session termination).
    - Logs the session end timestamp
    - Reads session metadata to produce a final summary
    - Cleans up log files older than CLEANUP_DAYS (default 7)
    - Removes any temp/cache files created during the session
    - Prints a formatted session-summary banner to the console
    Exit 0 always
#>

$ErrorActionPreference = 'Continue'

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG       = $script:LOG_SESSION
$sessionId = Get-SessionId
$ts        = Get-Date -Format $script:LOG_DATE_FMT
Ensure-LogsDir

# ── Load session metadata ─────────────────────────────────────────────────────
$meta        = Get-SessionMeta
$startTime   = if ($meta -and $meta.StartTime) { $meta.StartTime } else { 'unknown' }
$toolCalls   = if ($meta -and $meta.ToolCalls) { [int]$meta.ToolCalls } else { 0 }
$files       = if ($meta -and $meta.FilesChanged) { @($meta.FilesChanged) } else { @() }
$dangerous   = if ($meta -and $meta.DangerousPrompts) { [int]$meta.DangerousPrompts } else { 0 }
$errorCount  = if ($meta -and $meta.ErrorCount) { [int]$meta.ErrorCount } else { 0 }

# Compute session duration
$durationStr = 'N/A'
if ($startTime -ne 'unknown') {
    try {
        $start       = [datetime]::ParseExact($startTime, $script:LOG_DATE_FMT, $null)
        $end         = Get-Date
        $duration    = $end - $start
        $durationStr = '{0:D2}h {1:D2}m {2:D2}s' -f [int]$duration.Hours, [int]$duration.Minutes, [int]$duration.Seconds
    } catch { }
}

# ── Log session end ───────────────────────────────────────────────────────────
Write-HookInfo "=== sessionEnd BEGIN | session=$sessionId ===" $LOG
Write-HookInfo "Session duration: $durationStr" $LOG
Write-HookInfo "Files modified  : $($files.Count)" $LOG
Write-HookInfo "Tool calls      : $toolCalls" $LOG
Write-HookInfo "Errors occurred : $errorCount" $LOG
Write-HookInfo "Dangerous prompts seen: $dangerous" $LOG

# ── Cleanup: remove logs older than CLEANUP_DAYS ──────────────────────────────
Write-HookInfo "Cleaning up log files older than $($script:CLEANUP_DAYS) days..." $LOG
$cutoff    = (Get-Date).AddDays(-$script:CLEANUP_DAYS)
$logFiles  = Get-ChildItem -Path $script:LOGS_DIR -File -ErrorAction SilentlyContinue

$removedCount = 0
foreach ($lf in $logFiles) {
    # Never delete the active logs or session metadata
    $protectedFiles = @('session.log','errors.log','agent.log','prompts.log','.session-meta.json')
    if ($lf.Name -in $protectedFiles) { continue }

    if ($lf.LastWriteTime -lt $cutoff) {
        try {
            Remove-Item -Path $lf.FullName -Force -ErrorAction Stop
            $removedCount++
            Write-HookInfo "  Removed old log: $($lf.Name) (last modified: $($lf.LastWriteTime.ToString($script:LOG_DATE_FMT)))" $LOG
        } catch {
            Write-HookWarn "  Could not remove $($lf.Name): $_" $LOG
        }
    }
}
Write-HookInfo "Cleanup complete. Removed $removedCount file(s)." $LOG

# ── Cleanup: rotate oversized logs ────────────────────────────────────────────
$activeLogFiles = @($script:LOG_PROMPTS, $script:LOG_ERRORS, $script:LOG_TOOLS, $script:LOG_SMOKE, $script:LOG_SUBAGENT)
foreach ($lf in $activeLogFiles) {
    if (Test-Path $lf) {
        $sizeMB = (Get-Item $lf).Length / 1MB
        if ($sizeMB -gt $script:MAX_LOG_SIZE_MB) {
            $archive = "$lf.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
            try {
                Move-Item -Path $lf -Destination $archive -Force
                Write-HookInfo "Rotated oversized log: $lf -> $archive" $LOG
            } catch {
                Write-HookWarn "Could not rotate ${lf}: $_" $LOG
            }
        }
    }
}

# ── Cleanup: remove .session-meta.json at end of session ─────────────────────
if (Test-Path $script:SESSION_META) {
    try {
        Remove-Item -Path $script:SESSION_META -Force
        Write-HookInfo "Session metadata file removed." $LOG
    } catch {
        Write-HookWarn "Could not remove session metadata: $_" $LOG
    }
}

# ── Console: session summary banner ───────────────────────────────────────────
$line = '═' * 65
Write-Host ''
Write-Host $line -ForegroundColor Cyan
Write-Host '  COPILOT SESSION SUMMARY' -ForegroundColor Cyan
Write-Host $line -ForegroundColor Cyan
Write-Host "  Session ID   : $sessionId"       -ForegroundColor White
Write-Host "  Started      : $startTime"        -ForegroundColor White
Write-Host "  Ended        : $ts"               -ForegroundColor White
Write-Host "  Duration     : $durationStr"      -ForegroundColor White
Write-Host $line -ForegroundColor DarkCyan
Write-Host "  Tool calls   : $toolCalls"        -ForegroundColor White

if ($files.Count -gt 0) {
    Write-Host "  Files modified ($($files.Count)):"    -ForegroundColor White
    $files | Select-Object -First 10 | ForEach-Object {
        Write-Host "    · $_" -ForegroundColor DarkGray
    }
    if ($files.Count -gt 10) {
        Write-Host "    ... and $($files.Count - 10) more (see logs/agent.log)" -ForegroundColor DarkGray
    }
} else {
    Write-Host '  Files modified : (none)' -ForegroundColor White
}

Write-Host $line -ForegroundColor DarkCyan
if ($errorCount -gt 0) {
    Write-Host "  Errors         : $errorCount  (see logs/errors.log)" -ForegroundColor Red
} else {
    Write-Host '  Errors         : 0' -ForegroundColor Green
}
if ($dangerous -gt 0) {
    Write-Host "  Dangerous prompts : $dangerous  (see logs/prompts.log)" -ForegroundColor Yellow
}
if ($removedCount -gt 0) {
    Write-Host "  Log cleanup    : $removedCount old file(s) removed" -ForegroundColor DarkGray
}
Write-Host $line -ForegroundColor Cyan
Write-Host ''

Write-HookInfo "=== sessionEnd END | session=$sessionId ===" $LOG
exit 0
