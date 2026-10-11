#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

swift build -c release --product Macousel
bin_dir="$(swift build -c release --product Macousel --show-bin-path)"

app="build/Macousel.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Macousel" "$app/Contents/MacOS/Macousel"
cp support/info.plist "$app/Contents/Info.plist"
cp support/app-icon.icns "$app/Contents/Resources/app-icon.icns"

codesign --force --sign "${CODESIGN_IDENTITY:--}" "$app"
echo "$root/$app"
