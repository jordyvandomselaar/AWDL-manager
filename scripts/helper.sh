#!/bin/sh
# Installs or removes the root helper. Run as root.
set -eu
cd "$(dirname "$0")/.."

LABEL=app.jordy.awdl-manager.helper
BIN=/Library/PrivilegedHelperTools/$LABEL
PLIST=/Library/LaunchDaemons/$LABEL.plist

launchctl bootout "system/$LABEL" 2>/dev/null || true

case "$1" in
install)
  install -d -m 755 -o root -g wheel /Library/PrivilegedHelperTools
  install -m 755 -o root -g wheel build/awdl-helper "$BIN"
  install -m 644 -o root -g wheel launchd/helper.plist "$PLIST"
  launchctl bootstrap system "$PLIST"
  ;;
uninstall)
  rm -f "$BIN" "$PLIST"
  rm -rf "/Library/Application Support/AWDL Manager"
  ifconfig awdl0 up
  ;;
*)
  echo "usage: $0 install|uninstall" >&2
  exit 1
  ;;
esac
