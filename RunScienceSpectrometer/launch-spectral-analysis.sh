#!/usr/bin/env bash
# Launches Vernier Spectral Analysis as a standalone app window, acting like
# a bookmarked shortcut. Uses a dedicated Chromium profile so the installed
# PWA / service-worker cache persists between runs (needed for offline use).
set -euo pipefail

APP_URL="https://spectralanalysis.app/"
PROFILE_DIR="${HOME}/.config/spectral-analysis-app"

find_chromium() {
  for bin in chromium-browser chromium google-chrome-stable google-chrome; do
    if command -v "$bin" >/dev/null 2>&1; then
      echo "$bin"
      return 0
    fi
  done
  return 1
}

CHROMIUM_BIN="$(find_chromium)" || {
  echo "Error: no Chromium/Chrome binary found on PATH." >&2
  echo "Install one with: sudo apt install chromium-browser" >&2
  exit 1
}

if command -v bluetoothctl >/dev/null 2>&1; then
  if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "Bluetooth adapter is off; attempting to power it on..." >&2
    bluetoothctl power on >/dev/null 2>&1 || \
      echo "Warning: could not power on Bluetooth automatically." >&2
  fi
fi

mkdir -p "$PROFILE_DIR"

exec "$CHROMIUM_BIN" \
  --user-data-dir="$PROFILE_DIR" \
  --app="$APP_URL" \
  --start-maximized \
  "$@"
