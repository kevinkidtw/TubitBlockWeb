# TubitBlockWeb - Auto Setup and Launcher (Windows PowerShell)
# This script auto-installs Node.js, downloads the project, and starts openblock-link.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  TubitBlockWeb - One-Click Setup " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Check Node.js ----
Write-Host "[1/3] Checking Node.js..." -ForegroundColor Yellow

$npmPath = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmPath) {
    Write-Host ""
    Write-Host "  Node.js not found. Installing automatically..." -ForegroundColor Red

    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        Write-Host "  Using winget to install Node.js LTS..."
        winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "  Downloading Node.js installer..."
        $msiPath = Join-Path $env:TEMP "nodejs_setup.msi"
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" -OutFile $msiPath
        Write-Host "  Running installer..."
        Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qb" -Wait
        Remove-Item $msiPath -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host "  Node.js installed successfully!" -ForegroundColor Green
    Write-Host "  Please CLOSE this window, then double-click" -ForegroundColor Green
    Write-Host "  start_link.bat again to continue." -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}

Write-Host "  [OK] Node.js found: $($npmPath.Source)" -ForegroundColor Green

# ---- Step 2: Locate or download project ----
Write-Host "[2/3] Checking project files..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$linkDir = $null

# Check common locations
$candidates = @(
    (Join-Path $scriptDir "openblock-link"),
    (Join-Path $scriptDir "TubitBlockWeb\openblock-link"),
    (Join-Path $scriptDir "TubitBlockWeb-main\openblock-link")
)

foreach ($candidate in $candidates) {
    if (Test-Path (Join-Path $candidate "package.json")) {
        $linkDir = $candidate
        break
    }
}

if (-not $linkDir) {
    Write-Host "  Project not found. Downloading from GitHub..." -ForegroundColor Red
    Write-Host ""

    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        Write-Host "  Cloning via git (this may take several minutes)..."
        Set-Location $scriptDir
        git clone "https://github.com/kevinkidtw/TubitBlockWeb.git"
    } else {
        Write-Host "  Downloading ZIP archive (this may take several minutes)..."
        $zipPath = Join-Path $scriptDir "TubitBlockWeb.zip"
        Invoke-WebRequest -Uri "https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip" -OutFile $zipPath
        Write-Host "  Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath $scriptDir -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        $extractedDir = Join-Path $scriptDir "TubitBlockWeb-main"
        $targetDir = Join-Path $scriptDir "TubitBlockWeb"
        if (Test-Path $extractedDir) {
            Rename-Item $extractedDir $targetDir -ErrorAction SilentlyContinue
        }
    }

    $linkDir = Join-Path $scriptDir "TubitBlockWeb\openblock-link"

    if (-not (Test-Path (Join-Path $linkDir "package.json"))) {
        Write-Host ""
        Write-Host "  [ERROR] Download failed or project structure is unexpected." -ForegroundColor Red
        Write-Host "  Please download manually from: https://github.com/kevinkidtw/TubitBlockWeb" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "  Installing npm dependencies..."
    Set-Location $linkDir
    npm install
}

Write-Host "  [OK] Project found: $linkDir" -ForegroundColor Green

# ---- Step 3: Start server ----
Write-Host "[3/3] Starting openblock-link server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  TubitBlockWeb Link Server is starting!" -ForegroundColor Green
Write-Host "  Do NOT close this window. Minimize it instead." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

Set-Location $linkDir
npm start
