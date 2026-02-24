# TubitBlockWeb - 一鍵自動部署與啟動腳本 (Windows PowerShell)
# 本腳本會自動安裝 Node.js、下載專案原始碼，並啟動硬體連線助手。

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  TubitBlockWeb 一鍵自動部署與啟動工具" -ForegroundColor Cyan
Write-Host "  適用於 Windows 10 / 11 系統" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# ---- 第一步：檢查 Node.js 環境 ----
Write-Host "[1/3] 正在檢查 Node.js 環境..." -ForegroundColor Yellow

$npmPath = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmPath) {
    Write-Host ""
    Write-Host "  找不到 Node.js，正在為您自動安裝..." -ForegroundColor Red

    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        Write-Host "  偵測到微軟套件管理員 (winget)，正在安裝 Node.js LTS 版本..."
        winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "  正在從 Node.js 官方網站下載安裝檔..."
        $msiPath = Join-Path $env:TEMP "nodejs_setup.msi"
        try {
            Import-Module BitsTransfer -ErrorAction SilentlyContinue
            Start-BitsTransfer -Source "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" -Destination $msiPath -Description "正在下載 Node.js 安裝檔..." -DisplayName "Node.js LTS"
        } catch {
            Write-Host "  BITS 傳輸不可用，改用備援方式下載..."
            Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" -OutFile $msiPath
        }
        Write-Host "  正在執行安裝程式，請在彈出的視窗中完成安裝..."
        Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qb" -Wait
        Remove-Item $msiPath -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host "  Node.js 安裝完成！" -ForegroundColor Green
    Write-Host "  請先關閉此視窗，然後重新雙擊 start_link.bat" -ForegroundColor Green
    Write-Host "  讓系統載入新的環境變數後繼續執行。" -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}

Write-Host "  [OK] 已找到 Node.js：$($npmPath.Source)" -ForegroundColor Green

# ---- 第二步：尋找或下載專案原始碼 ----
Write-Host "[2/3] 正在檢查專案檔案..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$linkDir = $null

# 依序搜尋可能的專案位置
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
    Write-Host "  找不到專案原始碼，正在從 GitHub 自動下載..." -ForegroundColor Red
    Write-Host ""

    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        Write-Host "  偵測到 Git，正在使用淺層複製 (--depth 1) 加速下載..." -ForegroundColor Cyan
        Write-Host "  (僅下載最新版本的檔案，略過歷史紀錄，速度將大幅提升)" -ForegroundColor DarkGray
        Write-Host ""
        Set-Location $scriptDir
        git clone --depth 1 "https://github.com/kevinkidtw/TubitBlockWeb.git"
    } else {
        Write-Host "  系統沒有安裝 Git，改用壓縮包下載..." -ForegroundColor Cyan
        Write-Host "  (檔案較大約 1.5GB，下載時間視網路速度而定)" -ForegroundColor DarkGray
        Write-Host ""
        $zipPath = Join-Path $scriptDir "TubitBlockWeb.zip"

        # 優先使用 BITS 傳輸 (支援進度條與斷點續傳)
        try {
            Import-Module BitsTransfer -ErrorAction Stop
            Write-Host "  使用 BITS 智慧傳輸中 (支援斷線續傳)..." -ForegroundColor Green
            Start-BitsTransfer -Source "https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip" -Destination $zipPath -Description "正在下載 TubitBlockWeb 專案壓縮包 (支援斷線續傳)..." -DisplayName "TubitBlockWeb"
        } catch {
            Write-Host "  BITS 傳輸不可用，改用備援方式下載 (無法斷點續傳)..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip" -OutFile $zipPath
        }

        Write-Host ""
        Write-Host "  正在解壓縮檔案..." -ForegroundColor Yellow
        Write-Host "  此步驟正在處理大型檔案，畫面暫時停止是正常現象。" -ForegroundColor DarkGray
        Write-Host "  請耐心等候 1-3 分鐘，切勿關閉此視窗！" -ForegroundColor DarkGray
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
        Write-Host "  [錯誤] 下載失敗或專案結構異常。" -ForegroundColor Red
        Write-Host "  請手動前往 https://github.com/kevinkidtw/TubitBlockWeb 下載。" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "  正在安裝專案所需的 npm 套件..." -ForegroundColor Yellow
    Write-Host "  此步驟需要下載並安裝數百個小型模組，畫面暫時停止是正常現象。" -ForegroundColor DarkGray
    Write-Host "  請耐心等候 1-3 分鐘，切勿關閉此視窗！" -ForegroundColor DarkGray
    Set-Location $linkDir
    npm install
}

Write-Host "  [OK] 已找到專案目錄：$linkDir" -ForegroundColor Green

# ---- 第三步：啟動連線服務 ----
Write-Host "[3/3] 正在啟動硬體連線助手..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  TubitBlockWeb 硬體連線助手啟動中！" -ForegroundColor Green
Write-Host "  請勿關閉此視窗，把它最小化即可。" -ForegroundColor Green
Write-Host "  現在請打開瀏覽器，前往老師提供的網頁連結開始寫程式！" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

Set-Location $linkDir
npm start
