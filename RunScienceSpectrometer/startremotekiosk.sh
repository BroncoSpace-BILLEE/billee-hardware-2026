#!/usr/bin/env bash
# Runs Spectral Analysis on a virtual display (the Jetson is headless) and
# shares that display over VNC, so it can be viewed/controlled from another
# machine on the same network with any VNC viewer.
#
# One-time install: sudo apt install -y xvfb x11vnc fluxbox
set -euo pipefail

DISPLAY_NUM=":1"
RESOLUTION="1600x900x24"
VNC_PORT="5900"
VNC_PASSWD_FILE="${HOME}/.vnc/spectral-analysis.passwd"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for bin in Xvfb x11vnc fluxbox; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Missing '$bin'. Install with: sudo apt install -y xvfb x11vnc fluxbox" >&2
    exit 1
  }
done

mkdir -p "$(dirname "$VNC_PASSWD_FILE")"
if [ ! -f "$VNC_PASSWD_FILE" ]; then
  echo "No VNC password set yet — choose one now (first-time setup only):"
  x11vnc -storepasswd "$VNC_PASSWD_FILE"
fi

cleanup() {
  echo "Shutting down virtual display and VNC..."
  kill "${X11VNC_PID:-}" "${FLUXBOX_PID:-}" "${XVFB_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

Xvfb "$DISPLAY_NUM" -screen 0 "$RESOLUTION" &
XVFB_PID=$!
sleep 1
export DISPLAY="$DISPLAY_NUM"

fluxbox &
FLUXBOX_PID=$!

x11vnc -display "$DISPLAY_NUM" -forever -shared -rfbport "$VNC_PORT" \
  -rfbauth "$VNC_PASSWD_FILE" -o "${HOME}/.vnc/spectral-analysis.log" &
X11VNC_PID=$!

echo "VNC ready on port ${VNC_PORT}."
echo "From another machine on the same network, connect a VNC viewer to: $(hostname -I | awk '{print $1}'):${VNC_PORT}"

"$SCRIPT_DIR/launch-spectral-analysis.sh"
