#!/usr/bin/env bash
set -euo pipefail

main() {
  local download_url="${MACOUSEL_DOWNLOAD_URL:-https://github.com/nmbrthirteen/macousel/releases/latest/download/Macousel.zip}"
  local install_dir="${MACOUSEL_INSTALL_DIR:-/Applications}"
  local minimum_macos=14
  local expected_identifier="dev.macousel.app"
  local quit_wait_seconds=10

  fail() {
    echo "error: $1" >&2
    exit 1
  }

  [ "$(uname -s)" = "Darwin" ] || fail "Macousel runs on macOS only."
  [ "$(uname -m)" = "arm64" ] || fail "Macousel needs an Apple silicon Mac."
  local macos_major
  macos_major="$(sw_vers -productVersion | cut -d. -f1)"
  [ "$macos_major" -ge "$minimum_macos" ] || fail "Macousel needs macOS $minimum_macos or later. This Mac runs $(sw_vers -productVersion)."

  local workdir
  workdir="$(mktemp -d)"
  trap "rm -rf '$workdir'" EXIT

  echo "Downloading Macousel..."
  curl -fsSL "$download_url" -o "$workdir/Macousel.zip" || fail "Download failed. Check your connection and try again."
  ditto -x -k "$workdir/Macousel.zip" "$workdir" || fail "The download could not be unpacked. Try again."
  [ -d "$workdir/Macousel.app" ] || fail "The download did not contain Macousel.app."

  codesign --verify --deep "$workdir/Macousel.app" >/dev/null 2>&1 || fail "The downloaded app failed its signature check. Your installed copy was not changed."
  local identifier
  identifier="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$workdir/Macousel.app/Contents/Info.plist" 2>/dev/null || true)"
  [ "$identifier" = "$expected_identifier" ] || fail "The downloaded app is not Macousel. Your installed copy was not changed."

  if pgrep -x Macousel >/dev/null; then
    echo "Quitting the running copy..."
    osascript -e 'quit app "Macousel"' >/dev/null 2>&1 || pkill -x Macousel || true
    local waited=0
    while pgrep -x Macousel >/dev/null && [ "$waited" -lt "$quit_wait_seconds" ]; do
      sleep 1
      waited=$((waited + 1))
    done
    if pgrep -x Macousel >/dev/null; then
      fail "Macousel is still running. Quit it, then run the installer again."
    fi
  fi

  xattr -dr com.apple.quarantine "$workdir/Macousel.app" 2>/dev/null || true
  mkdir -p "$install_dir"
  rm -rf "$install_dir/Macousel.app"
  mv "$workdir/Macousel.app" "$install_dir/Macousel.app"


  echo "Installed $install_dir/Macousel.app"
  echo "Open it. If macOS asks for Accessibility access, allow it."
}

main "$@"
