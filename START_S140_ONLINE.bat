@echo off
setlocal
title S-140 Meeting Scheduler Launcher v5.3
cd /d "%~dp0"

echo.
echo ================================================
echo   S-140 Meeting Scheduler - Online Mode v5.3
echo ================================================
echo.
echo IMPORTANT: Close the old v5.2 PowerShell server window first.
echo v5.3 keeps port 8769 so your existing publishers, weeks and history remain available.
echo.

start "S-140 SERVER v5.3 - KEEP THIS WINDOW OPEN" powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File "%~dp0START_S140_ONLINE.ps1"

timeout /t 4 /nobreak >nul
start "" "http://127.0.0.1:8769/?v=5.3"

echo.
echo Confirm that the app says: Running version: v5.3
echo.
timeout /t 4 /nobreak >nul
exit /b 0
