#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
TAG="v$VERSION"
DMG_PATH="$ROOT_DIR/dist/CapsMov-$VERSION-macOS.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must contain a semantic version such as 0.2.0" >&2
  exit 1
fi

if ! grep -q "currentVersion = \"$VERSION\"" "$ROOT_DIR/Sources/CapsloxCore/CapsMovRelease.swift"; then
  echo "CapsMovRelease.currentVersion does not match VERSION $VERSION" >&2
  exit 1
fi

if [[ "${1:-}" == "--verify-tag" ]] && [[ "${GITHUB_REF_NAME:-$TAG}" != "$TAG" ]]; then
  echo "Tag ${GITHUB_REF_NAME:-unknown} does not match VERSION $VERSION" >&2
  exit 1
fi

cd "$ROOT_DIR"
xcrun swift-format lint --strict --recursive Sources tests
swift test
tests/test-packaging.sh
scripts/build-dmg.sh --output "$DMG_PATH"
(cd "$(dirname "$DMG_PATH")" && shasum -a 256 "$(basename "$DMG_PATH")") > "$CHECKSUM_PATH"
(cd "$(dirname "$DMG_PATH")" && shasum -a 256 -c "$(basename "$CHECKSUM_PATH")")

echo "Prepared $DMG_PATH"
echo "Prepared $CHECKSUM_PATH"
