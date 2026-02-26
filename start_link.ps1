﻿# =====================================================================
# TubitBlockWeb 一鍵自動部署與啟動腳本 (Windows PowerShell)
# 功能：自動安裝 Node.js/Git、偵測 CPU 架構、下載對應的 ESP32 編譯器、
#       啟動 HTTP 靜態伺服器與 openblock-link 連線服務。
# =====================================================================

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---- 系統環境偵測 ----
$osArch = $env:PROCESSOR_ARCHITECTURE
$osVersion = [System.Environment]::OSVersion.Version
$osName = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  TubitBlockWeb 一鍵自動部署與啟動工具" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  作業系統: $osName" -ForegroundColor DarkGray
Write-Host "  CPU 架構: $osArch" -ForegroundColor DarkGray
Write-Host "  系統版本: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)" -ForegroundColor DarkGray
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# ---- 統一下載函數（不依賴 BITS，支援進度顯示）----
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$DisplayName
    )

    Write-Host "    正在下載: $DisplayName" -ForegroundColor DarkGray
    Write-Host "    來源: $Url" -ForegroundColor DarkGray

    try {
        # 使用 .NET WebClient（支援進度事件，且能跟隨 GitHub 302 重定向）
        $webClient = New-Object System.Net.WebClient

        # 註冊進度回報事件
        $progressData = @{ LastPercent = -1 }
        $eventHandler = {
            param($sender, $e)
            if ($e.ProgressPercentage -ne $progressData.LastPercent -and $e.ProgressPercentage % 5 -eq 0) {
                $progressData.LastPercent = $e.ProgressPercentage
                $receivedMB = [math]::Round($e.BytesReceived / 1MB, 1)
                $totalMB = if ($e.TotalBytesToReceive -gt 0) { [math]::Round($e.TotalBytesToReceive / 1MB, 1) } else { "?" }
                Write-Progress -Activity "下載 $DisplayName" -Status "${receivedMB} MB / ${totalMB} MB" -PercentComplete $e.ProgressPercentage
            }
        }
        $webClient.add_DownloadProgressChanged($eventHandler)

        # 非同步下載以觸發進度事件
        $task = $webClient.DownloadFileTaskAsync($Url, $OutFile)
        while (-not $task.IsCompleted) {
            Start-Sleep -Milliseconds 200
            # 處理進度事件
            [System.Windows.Forms.Application]::DoEvents() 2>$null
        }

        if ($task.IsFaulted) {
            throw $task.Exception.InnerException
        }

        Write-Progress -Activity "下載 $DisplayName" -Completed
        $fileSizeMB = [math]::Round((Get-Item $OutFile).Length / 1MB, 1)
        Write-Host "    下載完成 (${fileSizeMB} MB)" -ForegroundColor Green
    } catch {
        Write-Host "    WebClient 下載失敗，改用 Invoke-WebRequest..." -ForegroundColor Yellow
        # 關閉預設進度條避免版面錯亂
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
        $ProgressPreference = 'Continue'
        $fileSizeMB = [math]::Round((Get-Item $OutFile).Length / 1MB, 1)
        Write-Host "    下載完成 (${fileSizeMB} MB)" -ForegroundColor Green
    } finally {
        if ($webClient) { $webClient.Dispose() }
    }
}

# ---- 第一步：檢查 Node.js 環境 ----
Write-Host "[1/5] 正在檢查 Node.js 環境..." -ForegroundColor Yellow

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
        Download-FileWithProgress -Url "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" -OutFile $msiPath -DisplayName "Node.js LTS"
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

Write-Host "  [OK] 已找到 Node.js: $($npmPath.Source)" -ForegroundColor Green

# ---- 第二步：檢查並安裝 Git ----
Write-Host "[2/5] 正在檢查 Git 環境..." -ForegroundColor Yellow

$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "  找不到 Git，正在為您自動安裝..." -ForegroundColor Red

    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        Write-Host "  使用 winget 安裝 Git..." -ForegroundColor Cyan
        winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "  正在從 Git 官方網站下載安裝檔..." -ForegroundColor Cyan
        $gitInstaller = Join-Path $env:TEMP "Git-Setup.exe"
        Download-FileWithProgress -Url "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe" -OutFile $gitInstaller -DisplayName "Git for Windows"
        Write-Host "  正在執行 Git 安裝程式（靜默安裝）..."
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP-" -Wait
        Remove-Item $gitInstaller -ErrorAction SilentlyContinue
    }

    # 重新整理 PATH 環境變數
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $gitPath = Get-Command git -ErrorAction SilentlyContinue

    if (-not $gitPath) {
        Write-Host "  [警告] Git 安裝後仍無法偵測，可能需要重啟終端。" -ForegroundColor Yellow
        Write-Host "  將改用壓縮包方式下載專案。" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Git 安裝成功: $($gitPath.Source)" -ForegroundColor Green
    }
} else {
    Write-Host "  [OK] 已找到 Git: $($gitPath.Source)" -ForegroundColor Green
}

# ---- 第三步：尋找或下載專案原始碼（優先使用 Git）----
Write-Host "[3/5] 正在檢查專案檔案..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = $null
$linkDir = $null

# 依序搜尋可能的專案位置（同時支援新舊目錄名稱）
$candidates = @(
    $scriptDir,
    (Join-Path $scriptDir "TubitBlockWeb"),
    (Join-Path $scriptDir "TubitBlockWeb-main")
)
$linkDirNames = @("openblock-link", "tubitblock-link")

foreach ($candidate in $candidates) {
    foreach ($dirName in $linkDirNames) {
        $testLink = Join-Path $candidate $dirName
        if (Test-Path (Join-Path $testLink "package.json")) {
            $projectRoot = $candidate
            $linkDir = $testLink
            break
        }
    }
    if ($linkDir) { break }
}

if (-not $linkDir) {
    Write-Host "  找不到專案原始碼，正在從 GitHub 自動下載..." -ForegroundColor Red
    Write-Host ""

    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        Write-Host "  使用 Git 淺層複製 (--depth 1) 加速下載..." -ForegroundColor Cyan
        Write-Host "  (僅下載最新版本，略過歷史紀錄)" -ForegroundColor DarkGray
        Set-Location $scriptDir
        git clone --depth 1 "https://github.com/kevinkidtw/TubitBlockWeb.git"
    } else {
        Write-Host "  Git 不可用，改用壓縮包下載..." -ForegroundColor Yellow
        $zipPath = Join-Path $scriptDir "TubitBlockWeb.zip"

        Download-FileWithProgress -Url "https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip" -OutFile $zipPath -DisplayName "TubitBlockWeb 專案壓縮包"

        Write-Host ""
        Write-Host "  正在解壓縮檔案..." -ForegroundColor Yellow
        Write-Host "  此步驟正在處理大型檔案，畫面暫時停止是正常現象。" -ForegroundColor DarkGray
        Expand-Archive -Path $zipPath -DestinationPath $scriptDir -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        $extractedDir = Join-Path $scriptDir "TubitBlockWeb-main"
        $targetDir = Join-Path $scriptDir "TubitBlockWeb"
        if (Test-Path $extractedDir) {
            Rename-Item $extractedDir $targetDir -ErrorAction SilentlyContinue
        }
    }

    $projectRoot = Join-Path $scriptDir "TubitBlockWeb"

    # 嘗試兩種目錄名
    foreach ($dirName in $linkDirNames) {
        $testLink = Join-Path $projectRoot $dirName
        if (Test-Path (Join-Path $testLink "package.json")) {
            $linkDir = $testLink
            break
        }
    }

    if (-not $linkDir) {
        Write-Host ""
        Write-Host "  [錯誤] 下載失敗或專案結構異常。" -ForegroundColor Red
        Write-Host "  請手動前往 https://github.com/kevinkidtw/TubitBlockWeb 下載。" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  [OK] 已找到專案目錄: $linkDir" -ForegroundColor Green

# ---- 第四步：偵測系統架構並下載 ESP32 編譯器工具鏈 ----
Write-Host "[4/5] 正在檢查 ESP32 編譯器工具鏈..." -ForegroundColor Yellow

$toolsDir = Join-Path $linkDir "tools\Arduino\packages\esp32\tools"

if ($osArch -eq "ARM64") {
    Write-Host "  偵測到 Windows ARM64 系統" -ForegroundColor Cyan
    Write-Host "  注意: ESP32 工具鏈僅提供 x64 版本，將透過 x64 模擬層執行" -ForegroundColor Yellow
}
Write-Host "  對應平台: Windows x64" -ForegroundColor DarkGray

# 定義 6 個需要下載的工具
$toolList = @(
    @{
        Name = "esp-x32 (Xtensa 編譯器, ~254MB)"
        Url = "https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/xtensa-esp-elf-13.2.0_20240530-x86_64-w64-mingw32.zip"
        DestDir = "esp-x32\2405"
        StripPrefix = "xtensa-esp-elf"
    },
    @{
        Name = "esp-rv32 (RISC-V 編譯器, ~350MB)"
        Url = "https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/riscv32-esp-elf-13.2.0_20240530-x86_64-w64-mingw32.zip"
        DestDir = "esp-rv32\2405"
        StripPrefix = "riscv32-esp-elf"
    },
    @{
        Name = "esptool_py (燒錄工具, ~26MB)"
        Url = "https://github.com/espressif/arduino-esp32/releases/download/3.1.0-RC3/esptool-v4.9.dev3-win64.zip"
        DestDir = "esptool_py\4.9.dev3"
        StripPrefix = "esptool"
    },
    @{
        Name = "openocd-esp32 (除錯工具, ~3MB)"
        Url = "https://github.com/espressif/openocd-esp32/releases/download/v0.12.0-esp32-20241016/openocd-esp32-win64-0.12.0-esp32-20241016.zip"
        DestDir = "openocd-esp32\v0.12.0-esp32-20241016"
        StripPrefix = "openocd-esp32"
    },
    @{
        Name = "xtensa-esp-elf-gdb (Xtensa GDB, ~32MB)"
        Url = "https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/xtensa-esp-elf-gdb-14.2_20240403-x86_64-w64-mingw32.zip"
        DestDir = "xtensa-esp-elf-gdb\14.2_20240403"
        StripPrefix = "xtensa-esp-elf-gdb"
    },
    @{
        Name = "riscv32-esp-elf-gdb (RISC-V GDB, ~32MB)"
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

    # 檢查是否已存在
    if ((Test-Path $fullDest) -and (Get-ChildItem $fullDest -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
        Write-Host "  [OK] $Name 已存在，跳過下載" -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "  [DL] $Name" -ForegroundColor Cyan
    $zipFile = Join-Path $env:TEMP "esp32_tool_$(Get-Random).zip"
    $extractTemp = Join-Path $env:TEMP "esp32_extract_$(Get-Random)"

    Download-FileWithProgress -Url $Url -OutFile $zipFile -DisplayName $Name

    Write-Host "    正在解壓..." -ForegroundColor DarkGray

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
        Get-ChildItem -Path $extractTemp | Move-Item -Destination $fullDest -Force
    }

    # 清理
    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
    Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "  [OK] $Name 安裝完成" -ForegroundColor Green
}

Write-Host ""

$toolIndex = 0
foreach ($tool in $toolList) {
    $toolIndex++
    Write-Host "  ($toolIndex/6)" -NoNewline
    Download-EspTool -Name $tool.Name -Url $tool.Url -DestDir $tool.DestDir -StripPrefix $tool.StripPrefix
}

Write-Host ""
Write-Host "  ESP32 編譯器工具鏈就緒!" -ForegroundColor Green

# ---- 安裝 npm 依賴 ----
Write-Host ""
Write-Host "正在檢查並安裝專案依賴套件 (npm install)..." -ForegroundColor Yellow
Write-Host "  此步驟需要下載並安裝數百個小型模組，畫面暫時停止是正常現象。" -ForegroundColor DarkGray
Set-Location $linkDir
npm install

# ---- 第五步：啟動服務 ----
Write-Host "[5/5] 正在啟動硬體連線助手..." -ForegroundColor Yellow
Write-Host ""

# 啟動 HTTP 靜態檔案伺服器 (port 8080)
Write-Host "正在啟動 HTTP 靜態伺服器 (port 8080)..." -ForegroundColor Cyan

$pythonPath = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonPath) {
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
}

$httpJob = $null
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
        Write-Host "  請手動使用瀏覽器開啟 www\index.html 檔案。" -ForegroundColor Yellow
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
