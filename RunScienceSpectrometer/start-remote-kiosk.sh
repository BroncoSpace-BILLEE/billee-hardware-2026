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

for bin in Xvfb x11vnc fluxbox setsid; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Missing '$bin'. Install with: sudo apt install -y xvfb x11vnc fluxbox util-linux" >&2
    exit 1
  }
done

mkdir -p "$(dirname "$VNC_PASSWD_FILE")"
if [ ! -f "$VNC_PASSWD_FILE" ]; then
  echo "No VNC password set yet — choose one now (first-time setup only):"
  x11vnc -storepasswd "$VNC_PASSWD_FILE"
fi

# Chromium needs to fully exit (its own graceful shutdown, plus any
# "leave site?" prompt) before Xvfb/x11vnc get torn down under it, or the
# next launch can start from a bad state. Give it a bounded window to close
# itself, then force it if it doesn't.
wait_for_exit() {
  local pid="$1" timeout="$2"
  for ((i = 0; i < timeout * 2; i++)); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.5
  done
  return 1
}

cleanup() {
  echo "Shutting down..."

  if [ -n "${CHROME_PID:-}" ] && kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "Asking Chromium to close..."
    kill -TERM "$CHROME_PID" 2>/dev/null || true
    if ! wait_for_exit "$CHROME_PID" 10; then
      echo "Chromium didn't exit in time, forcing it closed..." >&2
      kill -KILL "$CHROME_PID" 2>/dev/null || true
      wait_for_exit "$CHROME_PID" 5 || true
    fi
  fi

  echo "Tearing down virtual display and VNC..."
  kill "${X11VNC_PID:-}" "${FLUXBOX_PID:-}" "${XVFB_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Each child runs in its own session (setsid) so Ctrl-C at the terminal only
# signals this script, not Chromium/Xvfb/x11vnc directly — cleanup() above
# controls the shutdown order instead of the terminal racing it.
setsid Xvfb "$DISPLAY_NUM" -screen 0 "$RESOLUTION" &
XVFB_PID=$!
sleep 1
export DISPLAY="$DISPLAY_NUM"

setsid fluxbox &
FLUXBOX_PID=$!

setsid x11vnc -display "$DISPLAY_NUM" -forever -shared -rfbport "$VNC_PORT" \
  -rfbauth "$VNC_PASSWD_FILE" -o "${HOME}/.vnc/spectral-analysis.log" &
X11VNC_PID=$!

echo "VNC ready on port ${VNC_PORT}."
echo "From another machine on the same network, connect a VNC viewer to: $(hostname -I | awk '{print $1}'):${VNC_PORT}"

setsid "$SCRIPT_DIR/launch-spectral-analysis.sh" &
CHROME_PID=$!
wait "$CHROME_PID"
