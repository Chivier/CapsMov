#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
grep -q "currentVersion = \"$EXPECTED_VERSION\"" "$ROOT_DIR/Sources/CapsloxCore/CapsMovRelease.swift"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

APP_PATH="$TMP_DIR/CapsMov.app"
DMG_PATH="$TMP_DIR/CapsMov.dmg"

"$ROOT_DIR/scripts/build-app.sh" --output "$APP_PATH"

test -d "$APP_PATH/Contents/MacOS"
test -x "$APP_PATH/Contents/MacOS/CapsMov"
test -f "$APP_PATH/Contents/Info.plist"
test -f "$APP_PATH/Contents/Resources/CapsloxIcon.icns"
lipo "$APP_PATH/Contents/MacOS/CapsMov" -verify_arch arm64 x86_64

/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$APP_PATH/Contents/Info.plist" | grep -qx "CapsMov"
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$APP_PATH/Contents/Info.plist" | grep -qx "CapsMov"
/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$APP_PATH/Contents/Info.plist" | grep -qx "CapsMov"
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist" | grep -qx "com.capsmov.app"
/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$APP_PATH/Contents/Info.plist" | grep -qx "CapsloxIcon"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" | grep -qx "$EXPECTED_VERSION"
/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$APP_PATH/Contents/Info.plist" | grep -qx "true"
file "$APP_PATH/Contents/Resources/CapsloxIcon.icns" | grep -qi "icon"
"$APP_PATH/Contents/MacOS/CapsMov" --smoke-test-ui | grep -qx "CapsMov status bar UI ready; status icon ready"
"$APP_PATH/Contents/MacOS/CapsMov" --render-ui-preview "$TMP_DIR/permission-config.png" --permission-config | grep -qx "rendered $TMP_DIR/permission-config.png"
test -s "$TMP_DIR/permission-config.png"
"$APP_PATH/Contents/MacOS/CapsMov" --render-ui-preview "$TMP_DIR/settings.png" --settings | grep -qx "rendered $TMP_DIR/settings.png"
test -s "$TMP_DIR/settings.png"

codesign --verify --deep --strict "$APP_PATH"

"$ROOT_DIR/scripts/build-dmg.sh" --output "$DMG_PATH"

test -s "$DMG_PATH"
hdiutil imageinfo "$DMG_PATH" >/dev/null

echo "ok: packaging scripts produce a versioned, signed app bundle and DMG"
