@echo off
chcp 65001 > nul
TITLE TubitBlockWeb - 硬體連線助手 (Windows)

echo 正在檢查系統環境...

:: 檢查 npm 是否安裝
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo =======================================================
    echo [錯誤] 找不到 Node.js (npm)！
    echo 硬體連線助手需要 Node.js 才能運行。
    echo 請先前往官方網站下載並安裝 LTS 版本：https://nodejs.org/
    echo 安裝完成後，請重新啟動此腳本。
    echo =======================================================
    pause
    exit /b
)

:: 檢查是否有 openblock-link 資料夾
if exist "%~dp0openblock-link\package.json" (
    cd /d "%~dp0openblock-link"
) else if exist "%~dp0TubitBlockWeb\openblock-link\package.json" (
    cd /d "%~dp0TubitBlockWeb\openblock-link"
) else (
    echo 找不到 openblock-link，準備從 GitHub 自動下載...
    where git >nul 2>nul
    if %errorlevel% neq 0 (
        echo [錯誤] 找不到 git 程式，無法自動下載專案！
        echo 請先安裝 Git 或直接從 GitHub 網頁下載 ZIP 壓縮包。
        pause
        exit /b
    )
    git clone https://github.com/kevinkidtw/TubitBlockWeb.git
    cd /d "%~dp0TubitBlockWeb\openblock-link"
)

echo.
echo TubitBlockWeb - 正在啟動硬體連線助手...
echo 請保持此黑框視窗開啟，不要關閉，最小化即可！
echo.
npm start

pause
