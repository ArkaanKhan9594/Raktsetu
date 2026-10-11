@echo off
title RaktSetu - Blood Donation App
color 0C

echo ========================================
echo        RaktSetu - Starting App...
echo    Every donor, every drop, connected.
echo ========================================
echo.

:: Check if web build exists, if not build it
if not exist "%~dp0build\web\index.html" (
    echo [*] Building web app for the first time...
    echo     This may take a minute, please wait...
    cd /d "%~dp0"
    flutter build web
    echo.
    echo [+] Build complete!
    echo.
)

:: Kill any existing server on port 8080
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING 2^>nul') do (
    taskkill /PID %%a /F >nul 2>&1
)

echo [*] Starting local server on port 8080...
echo.

:: Start Python HTTP server with strict NO-CACHE in background
cd /d "%~dp0"
start /B python serve.py 8080 >nul 2>&1

:: Wait a moment for server to start
timeout /t 2 /nobreak >nul

:: Open in default browser
echo [+] Opening RaktSetu in your browser...
start http://localhost:8080

echo.
echo ========================================
echo   RaktSetu is running at:
echo   http://localhost:8080
echo.
echo   Press any key to STOP the server...
echo ========================================
pause >nul

:: Stop the server
echo.
echo [*] Stopping server...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING 2^>nul') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo [+] RaktSetu stopped. Goodbye!
timeout /t 2 /nobreak >nul
