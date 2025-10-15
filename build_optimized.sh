#!/bin/bash

echo "========================================"
echo "AuraMusic v1.7.0 - Optimized Build"
echo "========================================"
echo ""

echo "[1/5] Cleaning previous builds..."
flutter clean
echo ""

echo "[2/5] Getting dependencies..."
flutter pub get
echo ""

echo "[3/5] Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

echo "[4/5] Building optimized APKs (split per ABI)..."
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
echo ""

echo "[5/5] Build complete!"
echo ""
echo "========================================"
echo "Optimized APKs created:"
echo "- build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
echo "- build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "========================================"
echo ""
echo "APK sizes are 20-30% smaller than universal APK"
echo "Install the appropriate APK for your device"
echo ""
