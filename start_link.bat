@echo off
setlocal EnableDelayedExpansion

:: === TubitBlockWeb Launcher for Windows ===
:: This script auto-installs Node.js, downloads the project, and starts openblock-link.

chcp 65001 > nul 2>&1
TITLE TubitBlockWeb Launcher

echo =======================================================
echo   TubitBlockWeb - Auto Setup and Launcher
echo =======================================================
echo.

:: ------- Step 1: Check npm -------
where npm > nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Node.js found.
    goto STEP2
)

echo [!!] Node.js not found. Installing now...
echo.

where winget > nul 2>&1
if !errorlevel! equ 0 (
    echo Installing Node.js via winget...
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    goto REBOOT_MSG
)

echo Downloading Node.js installer via PowerShell...
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi' -OutFile '%TEMP%\nodejs.msi'"
if not exist "%TEMP%\nodejs.msi" (
    echo [ERROR] Download failed. Please install Node.js manually from https://nodejs.org/
    goto END
)
echo Running Node.js installer...
msiexec /i "%TEMP%\nodejs.msi" /qb
del "%TEMP%\nodejs.msi" > nul 2>&1

:REBOOT_MSG
echo.
echo =======================================================
echo   Node.js installation complete!
echo   Please CLOSE this window, then double-click
echo   this script again to continue setup.
echo =======================================================
goto END

:: ------- Step 2: Check project files -------
:STEP2
set "LINK_DIR="
if exist "%~dp0openblock-link\package.json" (
    set "LINK_DIR=%~dp0openblock-link"
)
if exist "%~dp0TubitBlockWeb\openblock-link\package.json" (
    set "LINK_DIR=%~dp0TubitBlockWeb\openblock-link"
)

if defined LINK_DIR (
    echo [OK] Project found.
    goto STEP3
)

echo [!!] Project not found. Downloading from GitHub...
echo.

where git > nul 2>&1
if !errorlevel! equ 0 (
    echo Cloning via git...
    cd /d "%~dp0"
    git clone https://github.com/kevinkidtw/TubitBlockWeb.git
    set "LINK_DIR=%~dp0TubitBlockWeb\openblock-link"
    goto RUN_NPM_INSTALL
)

echo Downloading ZIP via PowerShell...
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip' -OutFile 'TubitBlockWeb.zip'; Expand-Archive -Path 'TubitBlockWeb.zip' -DestinationPath '.' -Force; Remove-Item 'TubitBlockWeb.zip'"
if exist "%~dp0TubitBlockWeb-main" (
    move "%~dp0TubitBlockWeb-main" "%~dp0TubitBlockWeb" > nul 2>&1
)
set "LINK_DIR=%~dp0TubitBlockWeb\openblock-link"

:RUN_NPM_INSTALL
echo.
echo Installing dependencies... This may take a few minutes.
cd /d "!LINK_DIR!"
call npm install

:: ------- Step 3: Start server -------
:STEP3
cd /d "!LINK_DIR!"
echo.
echo =======================================================
echo   TubitBlockWeb - Link Server Starting...
echo   Do NOT close this window! Minimize it instead.
echo =======================================================
echo.
call npm start

:END
echo.
pause
