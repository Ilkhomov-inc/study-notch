#!/usr/bin/env bash
# Builds build/StudyNook.app from the Swift package.
#   Scripts/build-app.sh          build only
#   Scripts/build-app.sh --run    build, stop the running copy, start the new one
# Debug variables (passed through to the app with --run):
#   STUDYNOOK_FAST=1                  focus 20 s, rest 10 s
#   STUDYNOOK_PHASE=flight|arrival|rest|ready|idle   open straight into a phase
#   STUDYNOOK_PROGRESS=0.45           progress of that phase (0...1)
#   STUDYNOOK_EXPANDED=1              keep the island expanded
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

APP="build/StudyNook.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/StudyNook" "$APP/Contents/MacOS/StudyNook"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "Built $APP"

if [[ "${1:-}" == "--run" ]]; then
  pkill -x StudyNook 2>/dev/null || true
  sleep 0.3
  nohup "$APP/Contents/MacOS/StudyNook" >build/StudyNook.log 2>&1 &
  disown
  echo "Started (log: build/StudyNook.log)"
fi
