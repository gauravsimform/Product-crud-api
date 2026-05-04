#Requires -Version 5.1
<#
.SYNOPSIS
    preToolUse hook - validate and gate tool execution before it runs.
.DESCRIPTION
    Executed before every tool call Copilot makes.
    - Logs the tool name and its input/parameters
    - Scans tool input for dangerous database / file-system operations
    - BLOCKS dangerous tools by exiting with code 1
    - Records tool-start timestamp for execution-time measurement in postToolUse
    Exit 0  -> allow tool to run
    Exit 1  -> BLOCK tool execution (Copilot will not invoke the tool)
#>

$ErrorActionPreference = 'Continue'    # non-fatal except when we intentionally block

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG        = $script:LOG_TOOLS
$sessionId  = Get-SessionId
$ts         = Get-Date -Format $script:LOG_DATE_FMT
Ensure-LogsDir

# ── Read tool context from env vars ───────────────────────────────────────────
# Copilot sets these before invoking preToolUse:
#   COPILOT_TOOL_NAME       - the name of the tool being called
#   COPILOT_TOOL_PARAMETERS - JSON string with the tool's input parameters
$toolName   = if ($env:COPILOT_TOOL_NAME)       { $env:COPILOT_TOOL_NAME }       else { 'unknown-tool' }
$toolParams = if ($env:COPILOT_TOOL_PARAMETERS) { $env:COPILOT_TOOL_PARAMETERS } else { '{}' }

# ── Log tool invocation intent ─────────────────────────────────────────────────
$logEntry = "[$ts] [PRE-TOOL] tool=$toolName params=$toolParams session=$sessionId"
Add-Content -Path $LOG -Value $logEntry -Encoding UTF8
Write-Host "[preToolUse] Evaluating: $toolName" -ForegroundColor DarkCyan

# Store start time so postToolUse can compute elapsed ms
$env:COPILOT_TOOL_START_TIME = (Get-Date).ToString('o')   # ISO 8601 round-trip

# ── Increment session tool-call counter ───────────────────────────────────────
try {
    $meta = Get-SessionMeta
    if ($meta) {
        Save-SessionMeta @{
            SessionId        = $meta.SessionId
            StartTime        = $meta.StartTime
            WorkDir          = $meta.WorkDir
            FilesChanged     = @($meta.FilesChanged)
            ToolCalls        = [int]$meta.ToolCalls + 1
            DangerousPrompts = if ($meta.DangerousPrompts) { [int]$meta.DangerousPrompts } else { 0 }
        }
    }
} catch {
    Write-HookDebug "Could not update session metadata: $_" $LOG
}

# ── Dangerous-operation detection ─────────────────────────────────────────────
$allInput = "$toolName $toolParams"
$check    = Test-DangerousContent -Content $allInput -Patterns $script:DANGEROUS_TOOL_PATTERNS

if ($check.Matched) {
    $blockMsg = "BLOCKED: Tool '$toolName' matches dangerous pattern: '$($check.Pattern)'"
    Write-HookError $blockMsg $LOG

    Write-Host ''
    Write-Host ('X' * 70) -ForegroundColor Red
    Write-Host "  [preToolUse] TOOL BLOCKED"                                             -ForegroundColor Red
    Write-Host "  Tool   : $toolName"                                                    -ForegroundColor Yellow
    Write-Host "  Reason : Matches dangerous pattern '$($check.Pattern)'"                -ForegroundColor Yellow
    Write-Host "  Input  : $($toolParams.Substring(0, [Math]::Min(200, $toolParams.Length)))" -ForegroundColor White
    Write-Host ''
    Write-Host '  This tool was blocked to protect the database / file system.'          -ForegroundColor Cyan
    Write-Host '  If this is intentional, run the command manually in a terminal.'       -ForegroundColor Cyan
    Write-Host ('X' * 70) -ForegroundColor Red
    Write-Host ''

    exit 1    # <- BLOCKS the tool
}

# ── Per-tool specific validations ─────────────────────────────────────────────

switch -Regex ($toolName) {

    # Block direct HTTP DELETE if it targets all resources without an ID
    'http|web_request|invoke_http' {
        try {
            $p = $toolParams | ConvertFrom-Json -ErrorAction Stop
            if ($p.method -ieq 'DELETE' -and $p.url -imatch '/api/product\s*$') {
                Write-HookError "Blocked: mass-DELETE on /api/product without an ID." $LOG
                exit 1
            }
        } catch {
            # Could not parse params - allow and log
            Write-HookDebug "Could not parse HTTP tool params for safety check: $_" $LOG
        }
    }

    # Warn for any file-write tool targeting Migrations folder
    'write_file|create_file|edit_file|replace_string' {
        try {
            $p = $toolParams | ConvertFrom-Json -ErrorAction Stop
            $targetFile = if ($p.filePath) { $p.filePath } elseif ($p.path) { $p.path } else { '' }
            if ($targetFile -imatch 'Migrations') {
                Write-HookWarn "File write targeting Migrations folder: $targetFile - verify intent." $LOG
            }
        } catch { }
    }

    # Block terminal commands that contain known destructive patterns
    'run_in_terminal|run_terminal|execute_command|shell' {
        try {
            $p = $toolParams | ConvertFrom-Json -ErrorAction Stop
            $cmd = if ($p.command) { $p.command } else { '' }
            $cmdCheck = Test-DangerousContent -Content $cmd -Patterns $script:DANGEROUS_TOOL_PATTERNS
            if ($cmdCheck.Matched) {
                Write-HookError "Blocked terminal command. Pattern: '$($cmdCheck.Pattern)'. Command: $cmd" $LOG
                exit 1
            }
        } catch { }
    }
}

# ── Allow ─────────────────────────────────────────────────────────────────────
Write-HookInfo "ALLOWED: $toolName" $LOG
Write-Host "[preToolUse] Approved: $toolName" -ForegroundColor Green
exit 0
