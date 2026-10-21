#!/bin/bash
# Prepare Claude Code cloud sessions: install dependencies, build REA from this
# checkout so the project MCP server (.mcp.json) can start, and optionally
# provision Ghidra 12.1.x for native analysis.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

if ! node scripts/check-dependency-install.mjs >/dev/null 2>&1; then
  npm ci --no-audit --no-fund
fi
npm run build:cached

# Ghidra is bring-your-own. Use GHIDRA_INSTALL_DIR when set; otherwise fetch the
# latest 12.1.x release into a cache outside the repository. Failure is not
# fatal: static JavaScript/Electron analysis does not need Ghidra.
GHIDRA_CACHE="${REA_GHIDRA_CACHE_DIR:-$HOME/.cache/rea-ghidra}"
if [ -z "${GHIDRA_INSTALL_DIR:-}" ] \
  && ! compgen -G "$GHIDRA_CACHE/ghidra_12.1*_PUBLIC/support/analyzeHeadless" >/dev/null; then
  url=$(curl -fsSL "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases?per_page=20" 2>/dev/null \
    | grep -oE '"browser_download_url": *"[^"]*ghidra_12\.1(\.[0-9]+)?_PUBLIC_[0-9]+\.zip"' \
    | head -n 1 | sed -E 's/.*"(https[^"]*)"/\1/' || true)
  if [ -n "$url" ]; then
    mkdir -p "$GHIDRA_CACHE"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    if curl -fsSL -o "$tmp/ghidra.zip" "$url" && unzip -q "$tmp/ghidra.zip" -d "$GHIDRA_CACHE"; then
      echo "Installed Ghidra from $url into $GHIDRA_CACHE" >&2
    else
      echo "Ghidra download failed; native Ghidra analysis is unavailable." >&2
    fi
  else
    echo "Ghidra 12.1.x release not reachable (network policy?); native Ghidra analysis is unavailable." >&2
  fi
fi
