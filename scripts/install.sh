#!/usr/bin/env bash
# AgentHub installer.
#   curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash
#
# Options:  --version <x.y.z>   install a specific release
#           --uninstall         remove the app (your ~/.agenthub library is kept)
#           --help
# Env:      AGENTHUB_RELEASE_BASE  override the download base URL (testing)
#           AGENTHUB_INSTALL_DIR   override the install folder (testing)
set -euo pipefail

APP_NAME="AgentHub"
REPO="hertzhzzz/AgentHub"
DEFAULT_BASE="https://github.com/${REPO}/releases/latest/download"

say()  { printf '%s\n' "$*"; }
fail() { printf '\nError: %s\n' "$1" >&2; [ -n "${2:-}" ] && printf '%s\n' "$2" >&2; exit 1; }

usage() {
  cat <<'EOF'
AgentHub installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash
  curl -fsSL .../install.sh | bash -s -- --version 0.1.0
  curl -fsSL .../install.sh | bash -s -- --uninstall

Options:
  --version <x.y.z>  Install a specific release instead of the latest
  --uninstall        Quit and remove AgentHub (your tool library at ~/.agenthub is kept)
  --help             Show this help
EOF
}

MODE="install"
VERSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) MODE="uninstall" ;;
    --version)
      [ $# -ge 2 ] || fail "--version needs a number, for example: --version 0.1.0"
      VERSION="${2#v}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; fail "Unknown option: $1" ;;
  esac
  shift
done

[ "$(uname -s)" = "Darwin" ] || fail "AgentHub only runs on macOS." "This machine reports: $(uname -s)."

macos_major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$macos_major" -ge 14 ] 2>/dev/null || fail "AgentHub needs macOS 14 or newer (you have $(sw_vers -productVersion))." "Update macOS in System Settings, then run this again."

quit_app() {
  pgrep -x "$APP_NAME" >/dev/null 2>&1 || return 0
  say "Quitting running ${APP_NAME}..."
  osascript -e "quit app \"${APP_NAME}\"" >/dev/null 2>&1 || true
  i=0
  while pgrep -x "$APP_NAME" >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
    sleep 0.5; i=$((i + 1))
  done
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    fail "${APP_NAME} is still running." "Quit it from the menu bar or Dock, then run this again."
  fi
}

if [ -n "${AGENTHUB_INSTALL_DIR:-}" ]; then
  LOCATIONS=("$AGENTHUB_INSTALL_DIR")
else
  LOCATIONS=("/Applications" "$HOME/Applications")
fi

if [ "$MODE" = "uninstall" ]; then
  quit_app
  removed=0
  for dir in "${LOCATIONS[@]}"; do
    if [ -d "$dir/${APP_NAME}.app" ]; then
      rm -rf "${dir:?}/${APP_NAME}.app" || fail "Could not remove $dir/${APP_NAME}.app." "Drag it to the Trash by hand."
      say "Removed $dir/${APP_NAME}.app"
      removed=1
    fi
  done
  [ "$removed" -eq 1 ] || say "${APP_NAME} was not installed."
  say "Your tool library at ~/.agenthub was kept. Delete that folder yourself if you want it gone."
  exit 0
fi

# --- install ---
arch="$(uname -m)"
if [ "$arch" = "x86_64" ] && [ "$(sysctl -in sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
  arch="arm64"   # shell is running under Rosetta on Apple silicon
fi
case "$arch" in
  arm64|x86_64) ;;
  *) fail "Unsupported chip: $arch." ;;
esac

if [ -n "${AGENTHUB_RELEASE_BASE:-}" ]; then
  base="${AGENTHUB_RELEASE_BASE%/}"
elif [ -n "$VERSION" ]; then
  base="https://github.com/${REPO}/releases/download/v${VERSION}"
else
  base="$DEFAULT_BASE"
fi

asset="${APP_NAME}-macos-${arch}.zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

say "Installing ${APP_NAME} for ${arch}..."
say "Downloading ${asset}"
curl -fsSL "$base/$asset" -o "$tmp/$asset" \
  || fail "Download failed from $base/$asset" "Check your internet connection, or that this version exists: https://github.com/${REPO}/releases"
curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" \
  || fail "Could not download the checksum file." "Check your internet connection and try again."

expected="$(awk -v f="$asset" '$2 == f || $2 == "*" f {print $1; exit}' "$tmp/SHA256SUMS")"
[ -n "$expected" ] || fail "No checksum listed for $asset." "The release may be incomplete. Try again later."
actual="$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')"
[ "$expected" = "$actual" ] || fail "Checksum mismatch. The download is damaged or was changed." "Nothing was installed. Try again; if it keeps happening, open an issue on GitHub."
say "Checksum OK"

mkdir -p "$tmp/extract"
ditto -x -k "$tmp/$asset" "$tmp/extract" || fail "Could not unpack the download." "Try again."
[ -d "$tmp/extract/${APP_NAME}.app" ] || fail "The download does not contain ${APP_NAME}.app." "Open an issue on GitHub."

target=""
for dir in "${LOCATIONS[@]}"; do
  if [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null; then
    if [ -w "$dir" ]; then target="$dir"; break; fi
  fi
done
[ -n "$target" ] || fail "No writable Applications folder found." "Create ~/Applications and run this again."

quit_app

dest="$target/${APP_NAME}.app"
old=""
if [ -e "$dest" ]; then
  old="$target/.${APP_NAME}.old.$$"
  mv "$dest" "$old" || fail "Could not replace the existing ${APP_NAME}." "Quit it and try again."
fi
if ! mv "$tmp/extract/${APP_NAME}.app" "$dest" 2>/dev/null; then
  # different volume (or move failed): copy instead
  if ! ditto "$tmp/extract/${APP_NAME}.app" "$dest"; then
    [ -n "$old" ] && mv "$old" "$dest"
    fail "Could not copy ${APP_NAME} into $target." "Your previous version was kept."
  fi
fi
[ -z "$old" ] || rm -rf "$old"

say ""
say "Installed: $dest"
say "已安装到：$dest"
open "$dest" || say "Could not open it automatically. Open it from $target."
