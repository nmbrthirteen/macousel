#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

swift build -c release --product Macousel
bin_dir="$(swift build -c release --product Macousel --show-bin-path)"

app="build/Macousel.app"
plist="$app/Contents/Info.plist"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Macousel" "$app/Contents/MacOS/Macousel"
cp support/info.plist "$plist"
cp support/app-icon.icns "$app/Contents/Resources/app-icon.icns"

version="${VERSION:-$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist")}"
build_number="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
/usr/libexec/PlistBuddy \
  -c "Set :CFBundleShortVersionString $version" \
  -c "Set :CFBundleVersion $build_number" "$plist"

codesign --force --options runtime --sign "${CODESIGN_IDENTITY:--}" "$app"
echo "$root/$app"
