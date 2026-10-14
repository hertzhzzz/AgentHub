#!/usr/bin/env bash
# Usage: scripts/build-app.sh <arm64|x86_64> [version]
set -euo pipefail

ARCH="${1:-}"
case "$ARCH" in
  arm64) RS_ARCH=arm64 ;;
  x86_64) RS_ARCH=x64 ;;
  *) echo "usage: $0 <arm64|x86_64> [version]" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
VERSION="${2:-$(tr -d '[:space:]' < VERSION)}"
RS_VERSION="$(tr -d '[:space:]' < scripts/rulesync-version)"
BUNDLE_ID="io.github.hertzhzzz.agenthub"

echo "==> Building AgentHub $VERSION ($ARCH)"
swift build -c release --arch "$ARCH" --product AgentHub
BIN_DIR="$(swift build -c release --arch "$ARCH" --show-bin-path)"

APP="$ROOT/dist/$ARCH/AgentHub.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/bin"
cp "$BIN_DIR/AgentHub" "$APP/Contents/MacOS/AgentHub"
sed -e "s/__VERSION__/$VERSION/g" -e "s/__BUNDLE_ID__/$BUNDLE_ID/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
for b in "$BIN_DIR"/*.bundle; do
  [ -e "$b" ] && cp -R "$b" "$APP/Contents/Resources/"
done
[ -d "$APP/Contents/Resources/AgentHub_AgentHub.bundle" ] || { echo "error: resource bundle missing from app" >&2; exit 1; }

echo "==> Fetching rulesync $RS_VERSION ($RS_ARCH)"
CACHE="$ROOT/.cache/rulesync-$RS_VERSION"
mkdir -p "$CACHE"
BASE="https://github.com/dyoshikawa/rulesync/releases/download/v$RS_VERSION"
ASSET="rulesync-darwin-$RS_ARCH"
[ -f "$CACHE/$ASSET" ] || curl -fsSL -o "$CACHE/$ASSET" "$BASE/$ASSET"
[ -f "$CACHE/SHA256SUMS" ] || curl -fsSL -o "$CACHE/SHA256SUMS" "$BASE/SHA256SUMS"
( cd "$CACHE" && grep -E "[[:space:]]\*?$ASSET\$" SHA256SUMS | shasum -a 256 -c - )
cp "$CACHE/$ASSET" "$APP/Contents/Resources/bin/rulesync"
chmod +x "$APP/Contents/Resources/bin/rulesync"

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "$APP"

ZIP="$ROOT/dist/AgentHub-macos-$ARCH.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "$ZIP"
