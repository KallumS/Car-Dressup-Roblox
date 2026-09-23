#!/usr/bin/env bash
# Runs every offline check. Needs tests/setup-tools.sh to have been run first.
set -euo pipefail
TOOLS="${TOOLS:-$HOME/.cache/cardressup-tools}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$(mktemp -d)"

echo "== stylua";  stylua --check src
echo "== rojo";    rojo build default.project.json -o "$OUT/place.rbxl" > /dev/null && echo ok
echo "== luau-lsp"
rojo sourcemap default.project.json -o "$OUT/sourcemap.json" > /dev/null
if "$TOOLS/luau-lsp/build/luau-lsp" analyze --platform=roblox --definitions="$TOOLS/globalTypes.d.luau" \
	--sourcemap="$OUT/sourcemap.json" src 2>&1 | grep -v '^\[' | grep .; then
	echo "luau-lsp reported problems"; exit 1
fi
echo ok
echo "== harness"
LUAU="$TOOLS/luau/build/luau" API_DUMP="$TOOLS/API-Dump.json" tests/run.sh
