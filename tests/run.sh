#!/bin/sh
# Run with the standalone Luau CLI installed (https://luau.org/).
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT HUP INT TERM
cat tests/mocks.luau piano.lua tests/assertions.luau > "$tmp"
"${LUAU_BIN:-luau}" "$tmp"
