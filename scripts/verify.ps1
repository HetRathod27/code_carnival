# Verify script for QueueLess
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
Set-Location $rootDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " QueueLess Automated Verification Suite  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$failures = @()

# 1. Python Syntax / Ruff check (if installed)
Write-Host "`n[1/5] Checking Python formatting and linting..." -ForegroundColor Yellow
if (Test-Path ".\venv\Scripts\ruff.exe") {
    & ".\venv\Scripts\ruff.exe" check api
    if ($LASTEXITCODE -ne 0) { $failures += "Ruff linting failed" }
} else {
    Write-Host "Ruff not installed, skipping ruff check." -ForegroundColor Gray
}

# 2. Python Typecheck / Mypy (if installed)
Write-Host "`n[2/5] Checking Python typing..." -ForegroundColor Yellow
if (Test-Path ".\venv\Scripts\mypy.exe") {
    $env:MYPYPATH = "."
    & ".\venv\Scripts\mypy.exe" api
    if ($LASTEXITCODE -ne 0) { $failures += "Mypy typecheck failed" }
} else {
    Write-Host "Mypy not installed, skipping mypy." -ForegroundColor Gray
}

# 3. Pytest Full Test Suite
Write-Host "`n[3/5] Running Pytest suite..." -ForegroundColor Yellow
$env:PYTHONPATH = "."
if (Test-Path ".\venv\Scripts\pytest.exe") {
    & ".\venv\Scripts\pytest.exe" -v api/tests
    if ($LASTEXITCODE -ne 0) { $failures += "Pytest suite failed" }
} else {
    $failures += "Pytest is not installed in venv"
}

# 4. Web Typecheck and Build (if web/ exists)
Write-Host "`n[4/5] Checking Web application..." -ForegroundColor Yellow
if (Test-Path "web\package.json") {
    Push-Location web
    try {
        if (Test-Path "node_modules") {
            Write-Host "Running web typecheck..." -ForegroundColor Gray
            npm run typecheck
            if ($LASTEXITCODE -ne 0) { $failures += "Web typecheck failed" }

            Write-Host "Running web build..." -ForegroundColor Gray
            npm run build
            if ($LASTEXITCODE -ne 0) { $failures += "Web build failed" }
        } else {
            Write-Host "web/node_modules not found. Run npm install in web/." -ForegroundColor Gray
            $failures += "web/node_modules missing"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "web/ directory does not exist yet. Skipping web verification." -ForegroundColor Gray
}

# 5. Flutter Analyze (if mobile/ exists)
Write-Host "`n[5/5] Checking Flutter application..." -ForegroundColor Yellow
if (Test-Path "mobile\pubspec.yaml") {
    Push-Location mobile
    try {
        flutter analyze
        if ($LASTEXITCODE -ne 0) { $failures += "Flutter analyze failed" }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "mobile/ directory does not exist yet. Skipping Flutter verification." -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Cyan
if ($failures.Count -eq 0) {
    Write-Host " VERIFICATION PASSED: All checks green. " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host " VERIFICATION FAILED: $($failures.Count) issue(s) detected:" -ForegroundColor Red
    foreach ($err in $failures) {
        Write-Host " - $err" -ForegroundColor Red
    }
    Write-Host "========================================" -ForegroundColor Cyan
    exit 1
}
