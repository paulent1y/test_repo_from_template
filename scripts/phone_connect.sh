#!/usr/bin/env bash
# Shared helper: find phone via Tailscale or existing ADB, return "ip:port" device string.
# Source this file: source scripts/phone_connect.sh; device=$(find_and_connect)

set -euo pipefail

TAILSCALE="/c/Program Files/Tailscale/tailscale.exe"
ADB_PORT=5555

find_and_connect() {
  # Already connected?
  local existing
  existing=$(adb devices 2>/dev/null | grep -E ":[0-9]+[[:space:]]+device$" | head -1 | awk '{print $1}')
  if [[ -n "$existing" ]]; then
    echo "$existing"
    return 0
  fi

  # Find via Tailscale
  local ip=""
  if [[ -x "$TAILSCALE" ]]; then
    ip=$("$TAILSCALE" status 2>/dev/null | awk '/android/{print $1; exit}')
  fi

  if [[ -z "$ip" ]]; then
    echo "ERROR: No ADB device connected and no Android found in Tailscale." >&2
    exit 1
  fi

  local device="${ip}:${ADB_PORT}"
  echo "Connecting to $device..." >&2
  adb connect "$device" >/dev/null 2>&1
  sleep 1

  if ! adb devices | grep -q "^${device}[[:space:]]*device"; then
    echo "ERROR: ADB connect failed for $device" >&2
    exit 1
  fi

  echo "$device"
}
