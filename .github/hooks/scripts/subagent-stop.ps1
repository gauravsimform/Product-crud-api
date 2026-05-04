#Requires -Version 5.1
<#
.SYNOPSIS
    subagentStop hook - log sub-task completion and capture partial results.
.DESCRIPTION
    Executed when a Copilot sub-agent (spawned for a delegated sub-task)
    finishes its work.
    - Logs the sub-agent ID, task description, status, and any output
    - Captures and truncates partial results for the log
    - Provides a console status line
    Exit 0 always (observational hook)
#>

$ErrorActionPreference = 'Continue'

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG       = $script:LOG_SUBAGENT
$sessionId = Get-SessionId
$ts        = Get-Date -Format $script:LOG_DATE_FMT
Ensure-LogsDir

# ── Read sub-agent context from env vars ──────────────────────────────────────
# Copilot sets these before invoking subagentStop:
#   COPILOT_SUBAGENT_ID          - identifier for this sub-agent instance
#   COPILOT_SUBAGENT_TASK        - description of the delegated task
#   COPILOT_SUBAGENT_STATUS      - 'success' | 'error' | 'cancelled'
#   COPILOT_SUBAGENT_OUTPUT      - JSON string with the sub-agent's result
$subAgentId   = if ($env:COPILOT_SUBAGENT_ID)     { $env:COPILOT_SUBAGENT_ID }     else { "subagent-$(Get-Date -Format 'HHmmss')" }
$subAgentTask = if ($env:COPILOT_SUBAGENT_TASK)   { $env:COPILOT_SUBAGENT_TASK }   else { '[task not provided]' }
$subStatus    = if ($env:COPILOT_SUBAGENT_STATUS) { $env:COPILOT_SUBAGENT_STATUS } else { 'unknown' }
$subOutput    = if ($env:COPILOT_SUBAGENT_OUTPUT) { $env:COPILOT_SUBAGENT_OUTPUT } else { '{}' }

# Truncate large output before logging
$outputSnippet = if ($subOutput.Length -gt 800) {
    $subOutput.Substring(0, 800) + '...[truncated]'
} else {
    $subOutput
}

# ── Write structured log entry ────────────────────────────────────────────────
$separator = '─' * 60
Add-Content -Path $LOG -Value "`n$separator"                                    -Encoding UTF8
Add-Content -Path $LOG -Value "[$ts] [SUBAGENT-STOP] id=$subAgentId session=$sessionId" -Encoding UTF8
Add-Content -Path $LOG -Value "  Task   : $subAgentTask"                        -Encoding UTF8
Add-Content -Path $LOG -Value "  Status : $subStatus"                           -Encoding UTF8
Add-Content -Path $LOG -Value "  Output : $outputSnippet"                       -Encoding UTF8
Add-Content -Path $LOG -Value $separator                                         -Encoding UTF8

# ── Parse partial results if output is JSON ───────────────────────────────────
$resultSummary = 'N/A'
try {
    $parsed = $subOutput | ConvertFrom-Json -ErrorAction Stop
    # Attempt to extract a human-readable summary field
    $resultSummary = if ($parsed.summary)  { $parsed.summary  } `
                elseif ($parsed.message)   { $parsed.message  } `
                elseif ($parsed.result)    { $parsed.result   } `
                else                       { "(structured output - see $LOG)" }
} catch {
    # Not JSON - show first 120 chars as plain text
    $resultSummary = $subOutput.Substring(0, [Math]::Min(120, $subOutput.Length))
}

# ── Console output ─────────────────────────────────────────────────────────────
$statusColor = switch ($subStatus) {
    'success'   { 'Green'  }
    'error'     { 'Red'    }
    'cancelled' { 'Yellow' }
    default     { 'Gray'   }
}
Write-Host ''
Write-Host "[subagentStop] Sub-task $subStatus" -ForegroundColor $statusColor
Write-Host "  Sub-agent : $subAgentId"          -ForegroundColor White
Write-Host "  Task      : $subAgentTask"         -ForegroundColor White
Write-Host "  Summary   : $resultSummary"        -ForegroundColor DarkGray
Write-Host ''

# ── Level-specific logging ────────────────────────────────────────────────────
if ($subStatus -eq 'error') {
    Write-HookError "Sub-agent '$subAgentId' failed. Task: $subAgentTask" $LOG
} elseif ($subStatus -eq 'cancelled') {
    Write-HookWarn "Sub-agent '$subAgentId' was cancelled. Task: $subAgentTask" $LOG
} else {
    Write-HookSuccess "Sub-agent '$subAgentId' completed: $subAgentTask" $LOG
}

exit 0
