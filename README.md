# AWDL Manager

Menu bar toggle for `awdl0`, the Apple Wireless Direct Link interface behind AirDrop, AirPlay to Apple devices, Sidecar and Universal Control. Turning it off stops the Wi-Fi lag spikes it can cause.

Click the menu bar icon to turn AWDL on or off. Right-click for Quit.

## How it works

- `helper/awdl-helper.c` runs as a root LaunchDaemon from boot. It listens on the routing socket for interface changes and drops `awdl0` the moment macOS brings it up, as long as the mode is `off`.
- `app/main.swift` is the menu bar app. It starts at login through a LaunchAgent and writes `on` or `off` to `/Library/Application Support/AWDL Manager/mode`.
- The helper watches that file. The mode survives restarts, so the Mac comes back in the last mode you picked.

## Install

```sh
make install
```

Asks for your password once to install the helper.

## Uninstall

```sh
make uninstall
```

Removes everything and turns `awdl0` back on.

## Logs

```sh
log show --last 10m --predicate 'subsystem == "com.jordyvandomselaar.awdl-manager"'
```
