#Requires -Version 5.1
<#
.SYNOPSIS
    userPromptSubmitted hook - log the prompt and detect destructive operations.
.DESCRIPTION
    Executed each time the user submits a prompt to Copilot.
    - Appends the prompt to logs/prompts.log with a timestamp
    - Scans for dangerous keywords (delete all, drop, truncate, rm -rf, etc.)
    - Emits a prominent WARNING when a destructive pattern is detected
    - Returns exit 0 (non-blocking) even for dangerous prompts so Copilot
      can still run - the warning is advisory, not a hard block.
      Change exit code to 1 if you want to block dangerous prompts entirely.
#>

$ErrorActionPreference = 'Continue'    # non-fatal; never crash the session

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG        = $script:LOG_PROMPTS
$sessionId  = Get-SessionId
Ensure-LogsDir

# ── Read prompt from stdin JSON (VS Code passes hook input via stdin) ──────────
# VS Code sends a JSON object to stdin: { "prompt": "...", "sessionId": "...", ... }
# Fall back to env var for compatibility with other runtimes.
$stdinData  = $null
$userPrompt = '[prompt not available]'
try {
    if (-not [Console]::IsInputRedirected) { throw 'no stdin' }
    $raw = [Console]::In.ReadToEnd()
    if ($raw -and $raw.Trim() -ne '') {
        $stdinData  = $raw | ConvertFrom-Json -ErrorAction Stop
        $userPrompt = if ($stdinData.prompt) { $stdinData.prompt } else { '[prompt field missing in stdin JSON]' }
    }
} catch { }
if ($userPrompt -eq '[prompt not available]' -and $env:COPILOT_USER_PROMPT) {
    $userPrompt = $env:COPILOT_USER_PROMPT
}

# ── Log the prompt ────────────────────────────────────────────────────────────
$ts        = Get-Date -Format $script:LOG_DATE_FMT
$separator = '─' * 60
Add-Content -Path $LOG -Value "`n$separator" -Encoding UTF8
Add-Content -Path $LOG -Value "[$ts] [PROMPT] session=$sessionId" -Encoding UTF8
Add-Content -Path $LOG -Value "  $userPrompt" -Encoding UTF8
Add-Content -Path $LOG -Value $separator -Encoding UTF8

Write-HookInfo "Prompt logged (session=$sessionId, length=$($userPrompt.Length) chars)" $LOG

# ── Dangerous-keyword scan ────────────────────────────────────────────────────
$check = Test-DangerousContent -Content $userPrompt -Patterns $script:DANGEROUS_PROMPT_PATTERNS

if ($check.Matched) {
    $warnMsg = "DANGEROUS OPERATION DETECTED in prompt! Matched pattern: '$($check.Pattern)'"
    Write-HookWarn $warnMsg $LOG

    # Print a highly-visible console banner
    Write-Host ''
    Write-Host ('!' * 70) -ForegroundColor Red
    Write-Host '  WARNING: Your prompt may trigger a DESTRUCTIVE OPERATION.' -ForegroundColor Red
    Write-Host "  Matched pattern: $($check.Pattern)"                         -ForegroundColor Yellow
    Write-Host '  Prompt text excerpt:'                                        -ForegroundColor Yellow
    Write-Host "    $($userPrompt.Substring(0, [Math]::Min(200, $userPrompt.Length)))..." -ForegroundColor White
    Write-Host ''
    Write-Host '  Please confirm the intent before proceeding.'                -ForegroundColor Cyan
    Write-Host '  Review: logs/prompts.log for the full prompt.'               -ForegroundColor Cyan
    Write-Host ('!' * 70) -ForegroundColor Red
    Write-Host ''

    # ── Increment a session-level dangerous-prompt counter ────────────────────
    $meta = Get-SessionMeta
    if ($meta) {
        $count = if ($meta.DangerousPrompts) { [int]$meta.DangerousPrompts + 1 } else { 1 }
        Save-SessionMeta @{
            SessionId        = $meta.SessionId
            StartTime        = $meta.StartTime
            WorkDir          = $meta.WorkDir
            FilesChanged     = @($meta.FilesChanged)
            ToolCalls        = [int]$meta.ToolCalls
            DangerousPrompts = $count
        }
    }

    # Advisory warning only - exit 0 lets Copilot proceed.
    # Change to exit 1 to hard-block the prompt.
    exit 0
}

# ── Keyword hints (non-destructive but noteworthy) ────────────────────────────
$hints = @('migration', 'seed', 'scaffold', 'package', 'nuget', 'docker', 'deploy')
foreach ($hint in $hints) {
    if ($userPrompt -imatch $hint) {
        Write-HookInfo "Prompt contains keyword '$hint' - noting for context." $LOG
    }
}

Write-HookInfo 'Prompt scan complete. No destructive patterns found.' $LOG
exit 0
