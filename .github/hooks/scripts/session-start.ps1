#Requires -Version 5.1
<#
.SYNOPSIS
    sessionStart hook - build, test, health-check, Swagger, and smoke test.
.DESCRIPTION
    Executed once when a Copilot agent session begins.
    Steps (in order):
      1. Build the .NET solution - fail fast on compilation errors
      2. Run unit tests
      3. Check if the API is running; start it if not
      4. Poll /health until the API is ready (or timeout)
      5. Validate the Swagger endpoint
      6. Run Product API smoke tests
    Exit 0  -> session may proceed
    Exit 1  -> critical pre-condition failed; Copilot session is blocked
#>

$ErrorActionPreference = 'Stop'

# ── Bootstrap ─────────────────────────────────────────────────────────────────
. (Join-Path $PSScriptRoot 'common.ps1')

$LOG        = $script:LOG_SESSION
$sessionId  = Get-SessionId
$workspaceRoot = (Get-Location).Path
$solutionDir   = Join-Path $workspaceRoot 'ProductCrudApi'
$csprojPath    = Join-Path $solutionDir 'ProductCrudApi.csproj'
$apiUrl        = $script:API_BASE_URL

Ensure-LogsDir
Write-HookInfo "=== sessionStart BEGIN | session=$sessionId ===" $LOG

# Initialize session metadata (used by agentStop / sessionEnd)
Save-SessionMeta @{
    SessionId    = $sessionId
    StartTime    = (Get-Date -Format $script:LOG_DATE_FMT)
    WorkDir      = $workspaceRoot
    FilesChanged = @()
    ToolCalls    = 0
}

# ── STEP 1: Build solution ────────────────────────────────────────────────────
Write-HookInfo 'STEP 1/6 - Building solution...' $LOG
try {
    $buildOutput = & dotnet build $csprojPath --configuration Debug --no-incremental 2>&1
    $buildOutput | ForEach-Object { Write-HookDebug "  build: $_" $LOG }

    if ($LASTEXITCODE -ne 0) {
        Write-HookError 'Build FAILED. Resolve compilation errors before starting a Copilot session.' $LOG
        Write-Host "`n[sessionStart] BUILD FAILED - see logs/session.log for details." -ForegroundColor Red
        exit 1
    }
    Write-HookSuccess 'Build succeeded.' $LOG
} catch {
    Write-HookError "Build step threw an exception: $_" $LOG
    exit 1
}

# ── STEP 2: Run unit tests ────────────────────────────────────────────────────
Write-HookInfo 'STEP 2/6 - Running unit tests...' $LOG
try {
    # Discover test projects (any *Tests.csproj or *.Tests.csproj in the tree)
    $testProjects = Get-ChildItem -Path $workspaceRoot -Recurse -Filter '*Tests.csproj' -ErrorAction SilentlyContinue

    if ($testProjects.Count -eq 0) {
        Write-HookWarn 'No test projects found. Skipping unit-test step.' $LOG
    } else {
        foreach ($tp in $testProjects) {
            Write-HookInfo "  Running tests in: $($tp.Name)" $LOG
            $testOutput = & dotnet test $tp.FullName --no-build --logger "console;verbosity=minimal" 2>&1
            $testOutput | ForEach-Object { Write-HookDebug "  test: $_" $LOG }

            if ($LASTEXITCODE -ne 0) {
                Write-HookError "Tests FAILED in $($tp.Name). Fix failing tests before proceeding." $LOG
                Write-Host "`n[sessionStart] TESTS FAILED - see logs/session.log." -ForegroundColor Red
                exit 1
            }
        }
        Write-HookSuccess 'All unit tests passed.' $LOG
    }
} catch {
    Write-HookError "Test step threw an exception: $_" $LOG
    exit 1
}

# ── STEP 3: Start API if not running ─────────────────────────────────────────
Write-HookInfo 'STEP 3/6 - Checking API health...' $LOG
$apiRunning = Test-ApiHealth -BaseUrl $apiUrl -TimeoutSec 3

if (-not $apiRunning) {
    Write-HookWarn "API not reachable at $apiUrl. Attempting to start it..." $LOG
    try {
        # Start the API as a background process; redirect output to a start-up log
        $startLog = Join-Path $workspaceRoot 'logs/api-startup.log'
        Start-Process -FilePath 'dotnet' `
            -ArgumentList "run --project `"$csprojPath`" --no-build --urls `"$apiUrl`"" `
            -WorkingDirectory $solutionDir `
            -RedirectStandardOutput $startLog `
            -RedirectStandardError  "$startLog.err" `
            -NoNewWindow

        Write-HookInfo 'API process started. Waiting for readiness...' $LOG
    } catch {
        Write-HookError "Failed to start API: $_" $LOG
        exit 1
    }
}

# ── STEP 4: Poll /health until ready (max 30 s) ───────────────────────────────
Write-HookInfo 'STEP 4/6 - Polling /health endpoint...' $LOG
$maxWaitSec = 30
$elapsed    = 0
$ready      = $false

while ($elapsed -lt $maxWaitSec) {
    if (Test-ApiHealth -BaseUrl $apiUrl -TimeoutSec 3) {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 2
    $elapsed += 2
    Write-HookDebug "  Waiting for API... ($elapsed / $maxWaitSec s)" $LOG
}

if (-not $ready) {
    Write-HookError "API did not become healthy within $maxWaitSec seconds." $LOG
    Write-Host "`n[sessionStart] API HEALTH CHECK FAILED. Check logs/api-startup.log." -ForegroundColor Red
    exit 1
}
Write-HookSuccess "API is healthy at $apiUrl" $LOG

# ── STEP 5: Validate Swagger ──────────────────────────────────────────────────
Write-HookInfo 'STEP 5/6 - Validating Swagger endpoint...' $LOG
if (Test-SwaggerAvailable -BaseUrl $apiUrl) {
    Write-HookSuccess "Swagger UI available at $apiUrl/swagger/index.html" $LOG
} else {
    Write-HookWarn "Swagger endpoint is not accessible. Check appsettings / launchSettings." $LOG
    # Non-fatal: warn but do not block the session
}

# ── STEP 6: Smoke tests ───────────────────────────────────────────────────────
Write-HookInfo 'STEP 6/6 - Running Product API smoke tests...' $LOG
$smokeOk = Invoke-SmokeTests -BaseUrl $apiUrl

if (-not $smokeOk) {
    Write-HookWarn 'One or more smoke tests failed. Review logs/smoke-tests.log.' $LOG
    # Non-fatal: warn but allow session to proceed
} else {
    Write-HookSuccess 'All smoke tests passed.' $LOG
}

Write-HookInfo "=== sessionStart END | session=$sessionId ===" $LOG
Write-Host "`n[sessionStart] Environment ready. Copilot session active." -ForegroundColor Green
exit 0
