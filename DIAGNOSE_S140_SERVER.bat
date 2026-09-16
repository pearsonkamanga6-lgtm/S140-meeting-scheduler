@echo off
setlocal
title S-140 Server Diagnostic v5.3
cd /d "%~dp0"
echo Starting S-140 v5.3 server on port 8769...
powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File "%~dp0START_S140_ONLINE.ps1"
