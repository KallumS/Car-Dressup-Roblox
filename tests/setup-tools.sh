#!/usr/bin/env bash
# Installs the offline verification toolchain into $TOOLS (default ~/.cache/cardressup-tools).
# Idempotent; first run takes ~10 min (C++ builds) - run it in the background.
# Provides: rojo + stylua (cargo), luau CLI + luau-lsp (built from source with clang),
# Roblox type definitions and the Roblox API dump (raw.githubusercontent.com).
set -euo pipefail
TOOLS="${TOOLS:-$HOME/.cache/cardressup-tools}"
mkdir -p "$TOOLS"
cd "$TOOLS"

command -v rojo >/dev/null && command -v stylua >/dev/null || cargo install rojo stylua --locked

if [[ ! -x luau/build/luau ]]; then
	[[ -d luau ]] || git clone --depth 1 https://github.com/luau-lang/luau.git
	CC=clang CXX=clang++ cmake -S luau -B luau/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DLUAU_BUILD_TESTS=OFF
	ninja -C luau/build Luau.Repl.CLI
fi

if [[ ! -x luau-lsp/build/luau-lsp ]]; then
	[[ -d luau-lsp ]] || git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/JohnnyMorganz/luau-lsp.git
	# GCC trips -Werror=maybe-uninitialized in luau-lsp; clang + -Wno-error builds fine.
	CC=clang CXX=clang++ cmake -S luau-lsp -B luau-lsp/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-Wno-error"
	ninja -C luau-lsp/build Luau.LanguageServer.CLI
fi

[[ -f globalTypes.d.luau ]] || curl -sSfo globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
[[ -f API-Dump.json ]] || curl -sSfo API-Dump.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
echo "tools ready in $TOOLS"
