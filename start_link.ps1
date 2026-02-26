# =====================================================================
# TubitBlockWeb 一鍵自動部署與啟動腳本 (Windows PowerShell)
# 功能：自動安裝 Node.js、偵測 CPU 架構、下載對應的 ESP32 編譯器、
#       啟動 HTTP 靜態伺服器與 tubitblock-link 連線服務。
# =====================================================================

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  TubitBlockWeb 一鍵自動部署與啟動工具" -ForegroundColor Cyan
Write-Host "  適用於 Windows 10 / 11 系統" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# ---- 第一步：檢查 Node.js 環境 ----
Write-Host "[1/4] 正在檢查 Node.js 環境..." -ForegroundColor Yellow

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
Write-Host "[2/4] 正在檢查專案檔案..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = $null
$linkDir = $null

# 依序搜尋可能的專案位置
$candidates = @(
    $scriptDir,
    (Join-Path $scriptDir "TubitBlockWeb"),
    (Join-Path $scriptDir "TubitBlockWeb-main")
)

foreach ($candidate in $candidates) {
    $testLink = Join-Path $candidate "tubitblock-link"
    if (Test-Path (Join-Path $testLink "package.json")) {
        $projectRoot = $candidate
        $linkDir = $testLink
        break
    }
}

if (-not $linkDir) {
    Write-Host "  找不到專案原始碼，正在從 GitHub 自動下載..." -ForegroundColor Red
    Write-Host ""

    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        Write-Host "  偵測到 Git，正在使用淺層複製 (--depth 1) 加速下載..." -ForegroundColor Cyan
        Set-Location $scriptDir
        git clone --depth 1 "https://github.com/kevinkidtw/TubitBlockWeb.git"
    } else {
        Write-Host "  系統沒有安裝 Git，改用壓縮包下載..." -ForegroundColor Cyan
        Write-Host "  (檔案較大，下載時間視網路速度而定)" -ForegroundColor DarkGray
        $zipPath = Join-Path $scriptDir "TubitBlockWeb.zip"

        try {
            Import-Module BitsTransfer -ErrorAction Stop
            Write-Host "  使用 BITS 智慧傳輸中 (支援斷線續傳)..." -ForegroundColor Green
            Start-BitsTransfer -Source "https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip" -Destination $zipPath -Description "正在下載 TubitBlockWeb 專案壓縮包..." -DisplayName "TubitBlockWeb"
        } catch {
            Write-Host "  BITS 傳輸不可用，改用備援方式下載..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip" -OutFile $zipPath
        }

        Write-Host "  正在解壓縮檔案..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $scriptDir -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        $extractedDir = Join-Path $scriptDir "TubitBlockWeb-main"
        $targetDir = Join-Path $scriptDir "TubitBlockWeb"
        if (Test-Path $extractedDir) {
            Rename-Item $extractedDir $targetDir -ErrorAction SilentlyContinue
        }
    }

    $projectRoot = Join-Path $scriptDir "TubitBlockWeb"
    $linkDir = Join-Path $projectRoot "tubitblock-link"

    if (-not (Test-Path (Join-Path $linkDir "package.json"))) {
        Write-Host "  [錯誤] 下載失敗或專案結構異常。" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  [OK] 已找到專案目錄：$linkDir" -ForegroundColor Green

# ---- 第三步：偵測系統架構並下載 ESP32 編譯器工具鏈 ----
Write-Host "[3/4] 正在檢查 ESP32 編譯器工具鏈..." -ForegroundColor Yellow

$toolsDir = Join-Path $linkDir "tools\Arduino\packages\esp32\tools"
$arch = $env:PROCESSOR_ARCHITECTURE
Write-Host "  CPU 架構: $arch"
Write-Host "  對應平台: Windows x64"

# 定義 6 個需要下載的工具
$toolList = @(
    @{
        Name = "esp-x32 (Xtensa 編譯器)"
        Url = "https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/xtensa-esp-elf-13.2.0_20240530-x86_64-w64-mingw32.zip"
        DestDir = "esp-x32\2405"
        StripPrefix = "xtensa-esp-elf"
    },
    @{
        Name = "esp-rv32 (RISC-V 編譯器)"
        Url = "https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/riscv32-esp-elf-13.2.0_20240530-x86_64-w64-mingw32.zip"
        DestDir = "esp-rv32\2405"
        StripPrefix = "riscv32-esp-elf"
    },
    @{
        Name = "esptool_py (燒錄工具)"
        Url = "https://github.com/espressif/arduino-esp32/releases/download/3.1.0-RC3/esptool-v4.9.dev3-win64.zip"
        DestDir = "esptool_py\4.9.dev3"
        StripPrefix = "esptool"
    },
    @{
        Name = "openocd-esp32 (除錯工具)"
        Url = "https://github.com/espressif/openocd-esp32/releases/download/v0.12.0-esp32-20241016/openocd-esp32-win64-0.12.0-esp32-20241016.zip"
        DestDir = "openocd-esp32\v0.12.0-esp32-20241016"
        StripPrefix = "openocd-esp32"
    },
    @{
        Name = "xtensa-esp-elf-gdb (Xtensa GDB)"
        Url = "https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/xtensa-esp-elf-gdb-14.2_20240403-x86_64-w64-mingw32.zip"
        DestDir = "xtensa-esp-elf-gdb\14.2_20240403"
        StripPrefix = "xtensa-esp-elf-gdb"
    },
    @{
        Name = "riscv32-esp-elf-gdb (RISC-V GDB)"
        Url = "https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/riscv32-esp-elf-gdb-14.2_20240403-x86_64-w64-mingw32.zip"
        DestDir = "riscv32-esp-elf-gdb\14.2_20240403"
        StripPrefix = "riscv32-esp-elf-gdb"
    }
)

function Download-EspTool {
    param(
        [string]$Name,
        [string]$Url,
        [string]$DestDir,
        [string]$StripPrefix
    )

    $fullDest = Join-Path $toolsDir $DestDir

    # 檢查是否已存在（目錄非空代表已下載）
    if ((Test-Path $fullDest) -and (Get-ChildItem $fullDest -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
        Write-Host "  [OK] $Name 已存在，跳過下載" -ForegroundColor Green
        return
    }

    Write-Host "  [DL] 正在下載 $Name ..." -ForegroundColor Cyan
    $zipFile = Join-Path $env:TEMP "esp32_tool_$(Get-Random).zip"
    $extractTemp = Join-Path $env:TEMP "esp32_extract_$(Get-Random)"

    try {
        # 優先使用 BITS（支援進度條和斷點續傳）
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $Url -Destination $zipFile -Description "正在下載 $Name..." -DisplayName $Name
    } catch {
        # 備援：直接下載
        Write-Host "    改用備援方式下載 (可能較慢)..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $Url -OutFile $zipFile
    }

    Write-Host "  [EX] 正在解壓 $Name ..." -ForegroundColor Cyan

    # 解壓到臨時目錄
    New-Item -ItemType Directory -Path $extractTemp -Force | Out-Null
    Expand-Archive -Path $zipFile -DestinationPath $extractTemp -Force

    # 建立目標目錄
    New-Item -ItemType Directory -Path $fullDest -Force | Out-Null

    # 移動檔案（去掉頂層資料夾）
    $innerDir = Join-Path $extractTemp $StripPrefix
    if (Test-Path $innerDir) {
        Get-ChildItem -Path $innerDir | Move-Item -Destination $fullDest -Force
    } else {
        # 如果沒有頂層目錄（直接就是檔案），全部移動
        Get-ChildItem -Path $extractTemp | Move-Item -Destination $fullDest -Force
    }

    # 清理
    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
    Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "  [OK] $Name 下載完成" -ForegroundColor Green
}

Write-Host ""

foreach ($tool in $toolList) {
    Download-EspTool -Name $tool.Name -Url $tool.Url -DestDir $tool.DestDir -StripPrefix $tool.StripPrefix
}

Write-Host ""
Write-Host "  ESP32 編譯器工具鏈就緒" -ForegroundColor Green

# ---- 安裝 npm 依賴 ----
Write-Host ""
Write-Host "正在檢查並安裝專案依賴套件 (npm install)..." -ForegroundColor Yellow
Set-Location $linkDir
npm install

# ---- 第四步：啟動服務 ----
Write-Host "[4/4] 正在啟動硬體連線助手..." -ForegroundColor Yellow
Write-Host ""

# 啟動 HTTP 靜態檔案伺服器 (port 8080)
Write-Host "正在啟動 HTTP 靜態伺服器 (port 8080)..." -ForegroundColor Cyan

$pythonPath = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonPath) {
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
}

if ($pythonPath) {
    $httpJob = Start-Job -ScriptBlock {
        param($root, $py)
        & $py -m http.server 8080 --directory $root
    } -ArgumentList $projectRoot, $pythonPath.Source
    Write-Host "  HTTP 伺服器已啟動 (使用 Python)" -ForegroundColor Green
} else {
    # 嘗試使用 npx serve 作為備援
    $npxPath = Get-Command npx -ErrorAction SilentlyContinue
    if ($npxPath) {
        $httpJob = Start-Job -ScriptBlock {
            param($root)
            npx -y serve $root -l 8080 --no-clipboard
        } -ArgumentList $projectRoot
        Write-Host "  HTTP 伺服器已啟動 (使用 npx serve)" -ForegroundColor Green
    } else {
        Write-Host "  [警告] 找不到 Python 或 npx，無法啟動 HTTP 靜態伺服器！" -ForegroundColor Yellow
        Write-Host "  請手動使用瀏覽器開啟 www/index.html 檔案。" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  TubitBlockWeb 硬體連線助手啟動中！" -ForegroundColor Green
Write-Host "  請勿關閉此視窗，把它最小化即可。" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "  請用瀏覽器開啟: http://localhost:8080/www/index.html" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

Set-Location $linkDir
npm start

# 當 npm start 結束時，也關閉 HTTP 伺服器
if ($httpJob) {
    Stop-Job $httpJob -ErrorAction SilentlyContinue
    Remove-Job $httpJob -ErrorAction SilentlyContinue
}
