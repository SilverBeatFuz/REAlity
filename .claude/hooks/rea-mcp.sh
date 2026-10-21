#!/bin/bash
# Start the REA MCP server from this checkout. Selects a cached Ghidra 12.1.x
# installation when GHIDRA_INSTALL_DIR is not already set.
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if [ ! -f "$root/dist/main.js" ]; then
  echo "REA is not built; run 'npm ci && npm run build:cached' in $root." >&2
  exit 1
fi

if [ -z "${GHIDRA_INSTALL_DIR:-}" ]; then
  for dir in "${REA_GHIDRA_CACHE_DIR:-$HOME/.cache/rea-ghidra}"/ghidra_12.1*_PUBLIC; do
    if [ -x "$dir/support/analyzeHeadless" ]; then
      export GHIDRA_INSTALL_DIR="$dir"
    fi
  done
fi

exec node "$root/scripts/rea.mjs" mcp
