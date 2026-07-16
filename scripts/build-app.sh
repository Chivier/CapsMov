#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_PATH="$ROOT_DIR/dist/CapsMov.app"
SKIP_BUILD=0
VERSION_FILE="$ROOT_DIR/VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Version file not found at $VERSION_FILE" >&2
  exit 1
fi

APP_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
if ! [[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must contain a semantic version such as 0.2.0" >&2
  exit 1
fi

BUILD_NUMBER="${CAPSMOV_BUILD_NUMBER:-$(git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || echo 1)}"

usage() {
  cat <<'USAGE'
Usage: scripts/build-app.sh [--output PATH] [--skip-build]

Builds CapsMov.app around a universal arm64/x86_64 release executable.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_PATH="${2:?missing value for --output}"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT_DIR"
fi

BINARY_DIR="$(swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT_DIR" --show-bin-path)"
BINARY_PATH="$BINARY_DIR/capslox"
if [[ ! -x "$BINARY_PATH" ]]; then
  echo "Release binary not found at $BINARY_PATH" >&2
  exit 1
fi

ICON_PATH="$ROOT_DIR/assets/CapsloxIcon.icns"
if [[ ! -f "$ICON_PATH" ]]; then
  echo "App icon not found at $ICON_PATH" >&2
  exit 1
fi

rm -rf "$OUTPUT_PATH"
mkdir -p "$OUTPUT_PATH/Contents/MacOS" "$OUTPUT_PATH/Contents/Resources"

cp "$BINARY_PATH" "$OUTPUT_PATH/Contents/MacOS/CapsMov"
chmod 755 "$OUTPUT_PATH/Contents/MacOS/CapsMov"
cp "$ICON_PATH" "$OUTPUT_PATH/Contents/Resources/CapsloxIcon.icns"

cat > "$OUTPUT_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>CapsMov</string>
  <key>CFBundleDisplayName</key>
  <string>CapsMov</string>
  <key>CFBundleIconFile</key>
  <string>CapsloxIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.capsmov.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>CapsMov</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>CapsMov contributors</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$OUTPUT_PATH" >/dev/null

echo "Built $OUTPUT_PATH"
