#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

app="build/Macousel.app"
dmg="build/Macousel.dmg"
zip="build/Macousel.zip"

[ -d "$app" ] || scripts/bundle.sh

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"

rm -f "$dmg" "$zip"
hdiutil create -volname Macousel -srcfolder "$staging" -format UDZO -quiet "$dmg"
ditto -c -k --keepParent "$app" "$zip"

shasum -a 256 "$dmg" "$zip"
