@echo off
set "SCRIPT=%~dp0start_link.ps1"
if not exist "%SCRIPT%" powershell -ExecutionPolicy Bypass -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/kevinkidtw/TubitBlockWeb/main/start_link.ps1' -OutFile '%SCRIPT%'"
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT%"
pause
