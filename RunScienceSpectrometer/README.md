# Vernier Spectral Analysis on Jetson Orin AGX (offline, Bluetooth)

Short setup guide for running Vernier's Spectral Analysis PWA (`https://spectralanalysis.app`)
locally on a Jetson Orin AGX (L4T / Ubuntu, arm64), fully offline, talking to a
Go Direct spectrometer over Bluetooth LE.

This does **not** copy or repackage Vernier's app. It relies on the app's own
built-in PWA offline support (service worker + Web Bluetooth), which Vernier
documents as the intended way to run it without a network connection.

## Prerequisites

- Jetson Orin AGX running L4T Ubuntu (20.04/22.04-based)
- Internet access for the *one-time* first run only
- A Vernier Go Direct spectrometer, charged and powered on

## Quick setup

Do steps 1-3 below in one shot:

```bash
sudo ./jetson_install_me.sh
```

Installs Chromium/BlueZ/Xvfb/x11vnc/fluxbox, opens the app once on a
throwaway virtual display to let its service worker cache everything, then
closes and tells you it's ready to run offline. Needs internet for that one
run only. Skip to [step 5](#5-connect-the-spectrometer) once it's done, or
read on for what it's doing under the hood / how to do it by hand.

## 1. Install a recent Chromium

L4T's default apt Chromium can be old enough that Web Bluetooth is missing or
flag-gated. Install the latest available, and check the version:

```bash
sudo apt update
sudo apt install -y chromium-browser bluez
chromium-browser --version
```

If the version is older than ~110, look for a newer arm64 build (e.g. a
Chromium snap or a PPA) — Web Bluetooth support and its Linux/BlueZ backend
have had major fixes over time.

## 2. Make sure Bluetooth is up

```bash
sudo systemctl enable --now bluetooth
bluetoothctl power on
```

Add your user to the `bluetooth` group if you hit permission errors, then
log out/in:

```bash
sudo usermod -aG bluetooth "$USER"
```

## 3. First run: cache the app while online

1. Launch Chromium normally and go to `https://spectralanalysis.app`.
2. Click the install icon in the address bar (or menu → *Install Spectral
   Analysis*). This registers the service worker and precaches the app shell.
3. Close the browser.

## 4. Verify it works offline

1. Disconnect the Jetson from the network (or block it at the router).
2. Run the launcher script below.
3. Confirm the app UI loads from cache with no network.

## 5. Connect the spectrometer

In the app, use its "Connect device" control — this opens the standard Web
Bluetooth device chooser. Select the spectrometer from the list. No OS-level
pairing step is normally required; Web Bluetooth handles the GATT connection
directly.

## 6. Everyday launch

Use [`launch-spectral-analysis.sh`](launch-spectral-analysis.sh) to open the
app directly in its own window (like a desktop shortcut/bookmark), instead of
navigating there by hand each time.

## Viewing it from another machine (headless Jetson)

The app itself isn't a web server (unlike something like F Prime GDS), so
there's no port to just forward — it's a real GUI window that needs a
Bluetooth-capable browser. Since this Jetson has no monitor, use a virtual
display + VNC instead:

```bash
sudo apt install -y xvfb x11vnc fluxbox
./start-remote-kiosk.sh
```

First run asks you to set a VNC password, then it prints the Jetson's IP.
From another machine on the same network, connect to it with a VNC viewer at
`<jetson-ip>:5900`.

The viewing machine needs an **x86 Linux-compatible VNC viewer** — on that
machine (not the Jetson), run:

```bash
sudo ./host_install_me.sh
vncviewer <jetson-ip>:5900
```

Ctrl-C in the terminal running the script shuts down the virtual display,
Chromium, and the VNC server together.

## Troubleshooting

- **Device chooser doesn't show the spectrometer** — check `bluetoothctl
  show` reports the adapter as `Powered: yes`; try `sudo systemctl restart
  bluetooth`.
- **App won't load offline** — re-do step 3; the service worker only caches
  after a full successful load and install. Check
  `chrome://serviceworker-internals` for its registration status.
- **Web Bluetooth option missing entirely** — update Chromium; very old
  builds may need `chrome://flags/#enable-web-bluetooth` enabled manually.
- **`Failed to create ... SingletonLock: Permission denied`** — on Ubuntu,
  `chromium-browser` is usually the **snap** build, and its AppArmor
  confinement blocks writing a profile under `~/.config`. Check with
  `snap list chromium`. The launcher script already handles this: it stores
  the profile under `~/snap/chromium/common/spectral-analysis-app` when the
  snap is detected, instead of `~/.config`. If you still hit this error,
  delete the stale profile dir and rerun (never with `sudo` — running
  Chromium as root is a separate, unrelated failure):
  ```bash
  rm -rf ~/snap/chromium/common/spectral-analysis-app
  ./launch-spectral-analysis.sh
  ```
