@echo off
REM ==============================================================================
REM PadosiPro — All-in-One App Launcher (Windows)
REM ==============================================================================
echo ==================================================
echo   PadosiPro All-in-One App Launcher (Windows)
echo ==================================================

cd /d "%~dp0"

REM 1. Check if backend is already running on port 8000
curl -sf http://localhost:8000/health >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Backend is not running. Checking Docker...
    where docker >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [INFO] Launching backend via Docker Compose in background...
        docker compose up -d
        echo [INFO] Waiting for backend to become ready...
        timeout /t 5 >nul
    ) else (
        echo [WARNING] Docker not found. Please start backend manually:
        echo           cd backend ^&^& uvicorn src.main:app --port 8000
    )
) else (
    echo [SUCCESS] Backend is already running and healthy at http://localhost:8000
)

REM 2. Reverse port 8000 over USB via ADB if available
where adb >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Tunneling port 8000 over USB via ADB...
    adb reverse tcp:8000 tcp:8000 >nul 2>nul
)

echo.
echo Select an option:
echo   1) Install and launch pre-built Release APK on connected Android phone (Fastest)
echo   2) Run Flutter mobile app on Android Device / Emulator (with Hot Reload)
echo   3) Run in Google Chrome Browser
echo   4) Run as Windows Desktop Application
echo.
set /p choice="Enter choice [1/2/3/4] (default: 1): "
if "%choice%"=="" set choice=1

if "%choice%"=="1" (
    echo [INFO] Installing release APK (apk\padosipro-release.apk)...
    adb install -r apk\padosipro-release.apk
    echo [INFO] Launching PadosiPro on Android device...
    adb shell monkey -p com.padosipro.padosi_pro -c android.intent.category.LAUNCHER 1
    echo [SUCCESS] App launched on Android device!
) else if "%choice%"=="2" (
    echo [INFO] Launching Flutter app on Android...
    cd mobile
    flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
) else if "%choice%"=="3" (
    echo [INFO] Launching in Google Chrome...
    cd mobile
    flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
) else if "%choice%"=="4" (
    echo [INFO] Launching Windows Desktop application...
    cd mobile
    flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1
) else (
    echo [ERROR] Invalid choice.
)

pause
