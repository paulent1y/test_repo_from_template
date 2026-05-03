#!/usr/bin/env bash
# Dev workflow: build debug APK, find phone, connect, install, run with live output.
# Usage: bash scripts/dev_run.sh
# Hot reload: press r | Hot restart: R | Quit: q

set -euo pipefail
cd "$(dirname "$0")/.."

source scripts/phone_connect.sh
device=$(find_and_connect)
echo "Device: $device"

flutter run -d "$device"
