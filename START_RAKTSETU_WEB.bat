@echo off
title RaktSetu Web App Launcher
echo ========================================================
echo       Starting RaktSetu Web Application on Laptop
echo ========================================================
echo.
echo Opening browser at http://localhost:8080 ...
cd /d "%~dp0raktsetu"
start "" http://localhost:8080
python serve.py 8080
pause
