#!/usr/bin/env bash
# QA workflow: build release APK (split-per-abi), find phone, install matching ABI, launch.
# Usage: bash scripts/qa_install.sh

set -euo pipefail
cd "$(dirname "$0")/.."

PACKAGE="com.example.claude_flutter_template"
ACTIVITY="com.example.claude_flutter_template.MainActivity"
APK_DIR="build/app/outputs/flutter-apk"

source scripts/phone_connect.sh
device=$(find_and_connect)
echo "Device: $device"

echo "Building release APK (split-per-abi)..."
flutter build apk --release --split-per-abi

# Detect device ABI
abi=$(adb -s "$device" shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r\n')
echo "Device ABI: $abi"

case "$abi" in
  arm64-v8a)   apk="${APK_DIR}/app-arm64-v8a-release.apk" ;;
  armeabi-v7a) apk="${APK_DIR}/app-armeabi-v7a-release.apk" ;;
  x86_64)      apk="${APK_DIR}/app-x86_64-release.apk" ;;
  *)
    echo "Unknown ABI '$abi', falling back to arm64-v8a"
    apk="${APK_DIR}/app-arm64-v8a-release.apk"
    ;;
esac

echo "Installing: $apk"
adb -s "$device" install -r "$apk"

echo "Launching $PACKAGE..."
adb -s "$device" shell am start -n "${PACKAGE}/${ACTIVITY}"

echo "Done. App running on device."
