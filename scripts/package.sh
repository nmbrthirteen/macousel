#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

app="build/Macousel.app"
dmg="build/Macousel.dmg"
zip="build/Macousel.zip"
tools="build/dmg-tools"
dmgbuild_version="1.6.5"

[ -d "$app" ] || scripts/bundle.sh

if [ ! -x "$tools/bin/dmgbuild" ]; then
  python3 -m venv "$tools"
  "$tools/bin/pip" install --quiet --disable-pip-version-check "dmgbuild==$dmgbuild_version"
fi

rm -f "$dmg" "$zip"
"$tools/bin/dmgbuild" \
  -s support/installer/dmg-settings.py \
  -D app="$app" \
  -D icon=support/app-icon.icns \
  -D background=support/installer/background.tiff \
  Macousel "$dmg" > /dev/null
ditto -c -k --keepParent "$app" "$zip"

shasum -a 256 "$dmg" "$zip"
