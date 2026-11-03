#!/usr/bin/env bash
set -euo pipefail

main() {
  # The release workflow fills in the tag and the zip's SHA-256, so this script
  # only installs the archive it was published with.
  local release_tag="@RELEASE_TAG@"
  local expected_sha256="${MACOUSEL_SHA256:-@ZIP_SHA256@}"
  local download_url="${MACOUSEL_DOWNLOAD_URL:-https://github.com/nmbrthirteen/macousel/releases/download/$release_tag/Macousel.zip}"
  local install_dir="${MACOUSEL_INSTALL_DIR:-/Applications}"
  local minimum_macos=14
  local expected_identifier="dev.macousel.app"
  # SHA-1 of the self-signed "Macousel Release Signing" certificate. The release workflow
  # refuses to publish an app signed by anything else.
  local signing_leaf="bfe5ad5f4d2b2611b728a0061118429e88031466"
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
  case "$expected_sha256$download_url" in
    *@*@*) fail "This copy of the installer was not published by a release. Download install.sh from the releases page." ;;
  esac

  local workdir
  workdir="$(mktemp -d)"
  trap "rm -rf '$workdir'" EXIT

  echo "Downloading Macousel..."
  curl -fsSL "$download_url" -o "$workdir/Macousel.zip" || fail "Download failed. Check your connection and try again."
  local actual_sha256
  actual_sha256="$(shasum -a 256 "$workdir/Macousel.zip" | cut -d' ' -f1)"
  [ "$actual_sha256" = "$expected_sha256" ] || fail "The download does not match the published SHA-256. Your installed copy was not changed."
  ditto -x -k "$workdir/Macousel.zip" "$workdir" || fail "The download could not be unpacked. Try again."
  [ -d "$workdir/Macousel.app" ] || fail "The download did not contain Macousel.app."

  codesign --verify --deep --strict \
    -R="identifier \"$expected_identifier\" and certificate leaf = H\"$signing_leaf\"" \
    "$workdir/Macousel.app" >/dev/null 2>&1 || fail "The downloaded app failed its signature check. Your installed copy was not changed."
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

  # The app is not notarized, so Gatekeeper would refuse it. The pinned hash and
  # signing certificate above stand in for that check.
  xattr -dr com.apple.quarantine "$workdir/Macousel.app" 2>/dev/null || true
  mkdir -p "$install_dir"
  local staged="$install_dir/.Macousel.app.new"
  local previous="$install_dir/.Macousel.app.old"
  rm -rf "$staged" "$previous"
  ditto "$workdir/Macousel.app" "$staged" || { rm -rf "$staged"; fail "Could not copy Macousel into $install_dir. Your installed copy was not changed."; }
  if [ -e "$install_dir/Macousel.app" ]; then
    mv "$install_dir/Macousel.app" "$previous" || { rm -rf "$staged"; fail "Could not replace $install_dir/Macousel.app. Your installed copy was not changed."; }
  fi
  if ! mv "$staged" "$install_dir/Macousel.app"; then
    [ -e "$previous" ] && mv "$previous" "$install_dir/Macousel.app"
    rm -rf "$staged"
    fail "Could not move Macousel into $install_dir. Your installed copy was not changed."
  fi
  rm -rf "$previous"

  echo "Installed $install_dir/Macousel.app"
  echo "Open it. If macOS asks for Accessibility access, allow it."
}

main "$@"
