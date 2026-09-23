#!/usr/bin/env bash
# Runs the offline test harness: executes CarBuilder/MapBuilder and the client
# UI against a mocked Roblox runtime using the standalone Luau CLI.
#   LUAU=/path/to/luau tests/run.sh
# Optionally set API_DUMP=/path/to/API-Dump.json to audit every property write.
set -euo pipefail
cd "$(dirname "$0")"
LUAU="${LUAU:-luau}"
OUT="$(mktemp -d)"
REPO=..

python3 bundle.py "$REPO" "$OUT/server.luau" server_tests.luau dump_props.luau > /dev/null
python3 bundle.py "$REPO" "$OUT/client.luau" client_tests.luau mock_client.luau dump_props.luau > /dev/null

"$LUAU" "$OUT/server.luau" > "$OUT/server.txt"
"$LUAU" "$OUT/client.luau" > "$OUT/client.txt"
grep -v '^PROP|' "$OUT/server.txt" "$OUT/client.txt" | sed 's/^.*\.txt://'

if [[ -n "${API_DUMP:-}" ]]; then
	cat "$OUT/server.txt" "$OUT/client.txt" | python3 check_props.py "$API_DUMP"
fi
