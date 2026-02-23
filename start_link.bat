@echo off
chcp 65001 > nul
TITLE TubitBlockWeb - 硬體連線助手 (Windows)
echo TubitBlockWeb - 正在啟動硬體連線助手...
echo 請保持此黑框視窗開啟，不要關閉，最小化即可！
echo.

cd %~dp0\openblock-link
npm start

pause
