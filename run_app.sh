#!/usr/bin/env bash
# ==============================================================================
# PadosiPro — Single Command All-in-One Launcher
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "=================================================="
echo "🚀 PadosiPro All-in-One Launcher"
echo "=================================================="

# 1. Check if backend is already running on port 8000
if ! curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    echo "⚠️ Backend is not running on port 8000."
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo "🐳 Starting backend via Docker Compose in background..."
        docker compose up -d
        echo "⏳ Waiting for backend to become ready..."
        for i in {1..20}; do
            if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
                echo "✅ Backend is healthy and ready at http://localhost:8000"
                break
            fi
            sleep 1
        done
    else
        echo "⚠️ Docker is not available or daemon is inactive."
        echo "Tip: Run 'sudo systemctl start docker' or run backend manually:"
        echo "     cd backend && uvicorn src.main:app --port 8000"
    fi
else
    echo "✅ Backend is already up and healthy at http://localhost:8000"
fi

# 2. Reverse port 8000 over USB via ADB
if command -v adb >/dev/null 2>&1; then
    echo "🔗 Tunneling port 8000 over USB via ADB..."
    adb reverse tcp:8000 tcp:8000 2>/dev/null || true
fi

# 3. Check for connected Android device
DEVICE_ID=$(adb devices 2>/dev/null | grep -w "device" | awk '{print $1}' | head -n 1 || true)

if [ -n "$DEVICE_ID" ]; then
    echo "📱 Found connected device: $DEVICE_ID"
    echo ""
    echo "Select an option:"
    echo "  1) Install and launch pre-built Release APK (Fastest, ~5 seconds)"
    echo "  2) Run via Flutter on device (with Hot Reload)"
    echo "  3) Run in Google Chrome Browser"
    read -p "Enter choice [1/2/3] (default: 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1)
            echo "📦 Installing release APK (apk/padosipro-release.apk)..."
            adb -s "$DEVICE_ID" install -r apk/padosipro-release.apk
            echo "🚀 Launching PadosiPro on device..."
            adb -s "$DEVICE_ID" shell monkey -p com.padosipro.padosi_pro -c android.intent.category.LAUNCHER 1
            echo "✅ App launched on $DEVICE_ID!"
            ;;
        2)
            echo "🔨 Launching Flutter development build..."
            cd mobile
            flutter run -d "$DEVICE_ID" --dart-define=API_BASE_URL=http://localhost:8000/api/v1
            ;;
        3)
            echo "🌐 Launching in Google Chrome..."
            cd mobile
            flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    echo "⚠️ No USB Android device detected."
    echo "Launching in Google Chrome..."
    cd mobile
    flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
fi
