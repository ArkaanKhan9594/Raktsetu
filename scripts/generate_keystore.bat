@echo off
echo ========================================================
echo RaktSetu - Android Release Upload Keystore Generator
echo ========================================================
echo.
echo This script generates an RSA 2048-bit keystore required by
echo the Google Play Store for signing your release builds (.aab).
echo.

set KEYSTORE_NAME=upload-keystore.jks
set KEY_ALIAS=upload

if exist "%KEYSTORE_NAME%" (
    echo [WARNING] %KEYSTORE_NAME% already exists in this folder!
    echo Delete or move it first if you wish to generate a new key.
    pause
    exit /b
)

set KEYTOOL_CMD=keytool
where keytool >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if exist "C:\Program Files\Java\jdk-25.0.2\bin\keytool.exe" (
        set KEYTOOL_CMD="C:\Program Files\Java\jdk-25.0.2\bin\keytool.exe"
    ) else (
        for /d %%D in ("C:\Program Files\Java\jdk*") do (
            if exist "%%D\bin\keytool.exe" set KEYTOOL_CMD="%%D\bin\keytool.exe"
        )
    )
)

%KEYTOOL_CMD% -genkey -v -keystore %KEYSTORE_NAME% -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias %KEY_ALIAS%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] %KEYSTORE_NAME% created successfully!
    echo.
    echo Next steps:
    echo 1. Move %KEYSTORE_NAME% to your 'android/app/' directory.
    echo 2. Copy 'android/key.properties.example' to 'android/key.properties'.
    echo 3. Enter your keystore password in 'android/key.properties'.
    echo 4. Run: flutter build appbundle --release
) else (
    echo.
    echo [ERROR] Keystore generation failed. Ensure JDK keytool is available.
)
pause
