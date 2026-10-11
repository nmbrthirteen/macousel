#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

engine="$(scripts/engine.sh)"
swift build -c release --product Macousel
bin_dir="$(swift build -c release --product Macousel --show-bin-path)"

app="build/Macousel.app"
plist="$app/Contents/Info.plist"
identity="${CODESIGN_IDENTITY:--}"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Helpers" "$app/Contents/Resources"
cp "$bin_dir/Macousel" "$app/Contents/MacOS/Macousel"
cp "$engine" "$app/Contents/Helpers/paneru"
cp support/info.plist "$plist"
cp support/app-icon.icns "$app/Contents/Resources/app-icon.icns"
cp support/engine-version support/licenses/*.txt "$app/Contents/Resources/"

version="${VERSION:-$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist")}"
build_number="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
/usr/libexec/PlistBuddy \
  -c "Set :CFBundleShortVersionString $version" \
  -c "Set :CFBundleVersion $build_number" "$plist"

codesign --force --options runtime --sign "$identity" "$app/Contents/Helpers/paneru"
codesign --force --options runtime --sign "$identity" "$app"
echo "$root/$app"
