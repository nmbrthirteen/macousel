#!/usr/bin/env bash
set -euo pipefail

download_url="${MACOUSEL_DOWNLOAD_URL:-https://github.com/nmbrthirteen/macousel/releases/latest/download/Macousel.zip}"
install_dir="${MACOUSEL_INSTALL_DIR:-/Applications}"
minimum_macos=26

fail() {
  echo "error: $1" >&2
  exit 1
}

[ "$(uname -s)" = "Darwin" ] || fail "Macousel runs on macOS only."
[ "$(uname -m)" = "arm64" ] || fail "Macousel needs an Apple silicon Mac."
macos_major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$macos_major" -ge "$minimum_macos" ] || fail "Macousel needs macOS $minimum_macos or later. This Mac runs $(sw_vers -productVersion)."

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Downloading Macousel..."
curl -fsSL "$download_url" -o "$workdir/Macousel.zip" || fail "Download failed. Check your connection and try again."
ditto -x -k "$workdir/Macousel.zip" "$workdir"
[ -d "$workdir/Macousel.app" ] || fail "The download did not contain Macousel.app."

if pgrep -x Macousel >/dev/null; then
  echo "Quitting the running copy..."
  osascript -e 'quit app "Macousel"' >/dev/null 2>&1 || pkill -x Macousel || true
fi

xattr -dr com.apple.quarantine "$workdir/Macousel.app" 2>/dev/null || true
mkdir -p "$install_dir"
rm -rf "$install_dir/Macousel.app"
mv "$workdir/Macousel.app" "$install_dir/Macousel.app"

echo "Installed $install_dir/Macousel.app"
echo "Open it, then grant Accessibility access when macOS asks."
