#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(tr -d '[:space:]' < "$root/support/engine-version")"
out="$root/build/engine-$version"
binary="$out/bin/paneru"
export PATH="$HOME/.cargo/bin:$PATH"

if ! command -v cargo > /dev/null; then
  echo "Install Rust from https://rustup.rs, then run this again." >&2
  exit 1
fi

bridge_source="$root/engine-bridge"
patches="$root/support/engine-patches"
if [ ! -x "$binary" ] || [ -n "$(find "$patches" -newer "$binary")" ]; then
  crate="$root/build/paneru-$version.crate"
  source="$root/build/engine-source-$version"
  checksum="$(grep -A3 '^name = "paneru"$' "$bridge_source/Cargo.lock" \
    | sed -n 's/^checksum = "\(.*\)"$/\1/p')"
  mkdir -p "$root/build"
  curl --fail --silent --show-error --location \
    "https://static.crates.io/crates/paneru/paneru-$version.crate" --output "$crate"
  if [ "$(shasum -a 256 "$crate" | cut -d' ' -f1)" != "$checksum" ]; then
    echo "The Paneru $version download does not match engine-bridge/Cargo.lock." >&2
    exit 1
  fi
  rm -rf "$source"
  mkdir -p "$source"
  tar -xzf "$crate" -C "$source" --strip-components 1
  for patch in "$patches"/*.patch; do
    patch --quiet --strip 1 --directory "$source" < "$patch" >&2
  done
  cargo install --path "$source" --locked --force --no-default-features --root "$out" >&2
fi

bridge="$out/bin/engine-bridge"
if ! grep -q "paneru = { version = \"=$version\"" "$bridge_source/Cargo.toml"; then
  echo "engine-bridge/Cargo.toml must pin paneru to $version." >&2
  exit 1
fi
bridge_inputs=("$bridge_source/Cargo.toml" "$bridge_source/Cargo.lock" "$bridge_source/src")
if [ ! -x "$bridge" ] || [ -n "$(find "${bridge_inputs[@]}" -newer "$bridge")" ]; then
  cargo install --path "$bridge_source" --locked --force --root "$out" >&2
fi

echo "$binary"
