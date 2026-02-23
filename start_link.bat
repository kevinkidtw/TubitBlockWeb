@echo off
chcp 65001 > nul
TITLE TubitBlockWeb - 硬體連線助手 (Windows)

echo =======================================================
echo TubitBlockWeb 一鍵啟動環境 (Mac/Windows 通用架構)
echo =======================================================
echo 正在檢查系統環境...

:: 檢查 npm 是否安裝
where npm >nul 2>nul
if %errorlevel% equ 0 goto check_project

echo.
echo 找不到 Node.js (npm)，準備自動下載並安裝 Node.js...
echo.
where winget >nul 2>nul
if %errorlevel% neq 0 goto install_nodejs_ps

echo 偵測到微軟套件管理員 (winget)，正在安裝 Node.js LTS...
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
goto end_nodejs_install

:install_nodejs_ps
echo 系統未具備 winget，切換為直接下載安裝檔...
powershell -Command "$ErrorActionPreference = 'Stop'; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi' -OutFile 'nodejs.msi'"
if not exist nodejs.msi (
    echo [錯誤] 檔案下載失敗！請手動前往 https://nodejs.org/ 下載。
    pause
    exit /b
)
echo 正在執行安裝程式... [請在跳出的視窗中允許變更並完成安裝]
msiexec /i nodejs.msi /qb
del nodejs.msi

:end_nodejs_install
echo.
echo =======================================================
echo Node.js 安裝完畢！
echo 為了讓系統載入新的環境變數，請先將這個「黑色的視窗關閉」，
echo 然後「重新連按兩下這個啟動腳本」來繼續執行後續步驟。
echo =======================================================
pause
exit /b

:check_project
:: 檢查是否有 openblock-link 資料夾
if exist "%~dp0openblock-link\package.json" (
    cd /d "%~dp0openblock-link"
    goto start_server
)
if exist "%~dp0TubitBlockWeb\openblock-link\package.json" (
    cd /d "%~dp0TubitBlockWeb\openblock-link"
    goto start_server
)

echo.
echo 找不到 openblock-link，準備自動下載專案...
where git >nul 2>nul
if %errorlevel% neq 0 goto clone_ps

echo 偵測到 Git，正在從 GitHub 複製專案...
cd /d "%~dp0"
git clone https://github.com/kevinkidtw/TubitBlockWeb.git
cd /d "%~dp0TubitBlockWeb\openblock-link"
goto run_install

:clone_ps
echo 系統沒有安裝 Git，改用 PowerShell 直接下載壓縮包...
cd /d "%~dp0"
powershell -Command "$ErrorActionPreference = 'Stop'; Invoke-WebRequest -Uri 'https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip' -OutFile 'TubitBlockWeb.zip'; Expand-Archive -Path 'TubitBlockWeb.zip' -DestinationPath '.'; Remove-Item 'TubitBlockWeb.zip'"
move TubitBlockWeb-main TubitBlockWeb >nul 2>nul
cd /d "%~dp0TubitBlockWeb\openblock-link"

:run_install
echo.
echo 正在檢查並安裝專案依賴套件 (這可能需要幾分鐘的時間)...
call npm install

:start_server
echo.
echo =======================================================
echo TubitBlockWeb - 正在啟動硬體連線助手...
echo 請保持此黑框視窗開啟，不要關閉，把它最小化即可！
echo =======================================================
echo.
npm start

pause
