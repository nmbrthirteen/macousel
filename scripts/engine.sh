#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(tr -d '[:space:]' < "$root/support/engine-version")"
out="$root/build/engine-$version"
binary="$out/bin/paneru"
export PATH="$HOME/.cargo/bin:$PATH"

if [ ! -x "$binary" ]; then
  if ! command -v cargo > /dev/null; then
    echo "Install Rust from https://rustup.rs, then run this again." >&2
    exit 1
  fi
  cargo install paneru --version "$version" --locked --no-default-features --root "$out" >&2
fi

bridge_source="$root/engine-bridge"
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
