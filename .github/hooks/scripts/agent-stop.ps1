#Requires -Version 5.1
<#
.SYNOPSIS
    agentStop hook - summarize the agent turn and log all modified files.
.DESCRIPTION
    Executed when the Copilot agent finishes its current response turn
    (i.e., after all tool calls for a single user prompt complete).
    - Reads session metadata to calculate what happened this turn
    - Lists every file that was modified
    - Writes a structured turn-summary to logs/agent.log
    - Appends a brief human-readable recap to the console
    Exit 0 always (observational hook)
#>

$ErrorActionPreference = 'Continue'

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG       = $script:LOG_AGENT
$sessionId = Get-SessionId
$ts        = Get-Date -Format $script:LOG_DATE_FMT
Ensure-LogsDir

# ── Read context from Copilot env vars ───────────────────────────────────────
# COPILOT_AGENT_TURN_ID  - identifier for this particular agent turn (if available)
$turnId   = if ($env:COPILOT_AGENT_TURN_ID) { $env:COPILOT_AGENT_TURN_ID } else { "turn-$(Get-Date -Format 'HHmmss')" }

# ── Load session metadata ─────────────────────────────────────────────────────
$meta      = Get-SessionMeta
$turnTools = if ($meta -and $meta.ToolCalls)        { [int]$meta.ToolCalls }        else { 0 }
$files     = if ($meta -and $meta.FilesChanged)     { @($meta.FilesChanged) }       else { @() }
$dangerous = if ($meta -and $meta.DangerousPrompts) { [int]$meta.DangerousPrompts } else { 0 }

# ── Build summary ─────────────────────────────────────────────────────────────
$separator = '─' * 60
Add-Content -Path $LOG -Value "`n$separator"                           -Encoding UTF8
Add-Content -Path $LOG -Value "[$ts] [AGENT-STOP] turn=$turnId session=$sessionId" -Encoding UTF8
Add-Content -Path $LOG -Value "  Tool calls this session : $turnTools" -Encoding UTF8
Add-Content -Path $LOG -Value "  Dangerous prompts seen  : $dangerous" -Encoding UTF8
Add-Content -Path $LOG -Value "  Files modified ($($files.Count)):"   -Encoding UTF8

if ($files.Count -gt 0) {
    foreach ($f in $files) {
        Add-Content -Path $LOG -Value "    - $f" -Encoding UTF8
    }
} else {
    Add-Content -Path $LOG -Value '    (none)' -Encoding UTF8
}

# ── Also diff-check modified files vs git ─────────────────────────────────────
try {
    $gitStatus = & git -C (Get-Location) status --short 2>&1
    if ($LASTEXITCODE -eq 0 -and $gitStatus) {
        Add-Content -Path $LOG -Value "  Git working-tree changes:" -Encoding UTF8
        $gitStatus | ForEach-Object {
            Add-Content -Path $LOG -Value "    $_" -Encoding UTF8
        }
    }
} catch {
    Write-HookDebug "git status unavailable: $_" $LOG
}

Add-Content -Path $LOG -Value $separator -Encoding UTF8

# ── Console output ────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[agentStop] Agent turn complete.' -ForegroundColor Cyan
Write-Host "  Turn     : $turnId"            -ForegroundColor White
Write-Host "  Tools    : $turnTools"          -ForegroundColor White
Write-Host "  Modified : $($files.Count) file(s)" -ForegroundColor White
if ($files.Count -gt 0) {
    $files | ForEach-Object { Write-Host "    · $_" -ForegroundColor DarkGray }
}
if ($dangerous -gt 0) {
    Write-Host "  [!] Dangerous prompts in this session: $dangerous" -ForegroundColor Yellow
}
Write-Host ''

# ── Reset per-turn counters in metadata (keep file list) ─────────────────────
if ($meta) {
    Save-SessionMeta @{
        SessionId        = $meta.SessionId
        StartTime        = $meta.StartTime
        WorkDir          = $meta.WorkDir
        FilesChanged     = $files           # persist for sessionEnd
        ToolCalls        = 0                # reset for next turn
        DangerousPrompts = $dangerous
    }
}

exit 0
