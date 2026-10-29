#!/bin/sh
# Installs or removes the menu bar app and its login agent. Run as your user.
set -eu
cd "$(dirname "$0")/.."

LABEL=app.jordy.awdl-manager
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
rm -rf /Applications/AWDLManager.app

case "$1" in
install)
  cp -R build/AWDLManager.app /Applications/
  mkdir -p "$HOME/Library/LaunchAgents"
  cp launchd/agent.plist "$AGENT"
  launchctl bootstrap "$DOMAIN" "$AGENT"
  ;;
uninstall)
  rm -f "$AGENT"
  ;;
*)
  echo "usage: $0 install|uninstall" >&2
  exit 1
  ;;
esac
