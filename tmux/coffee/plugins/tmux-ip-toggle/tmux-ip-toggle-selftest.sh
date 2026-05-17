#!/usr/bin/env bash
set -euo pipefail

PLUGIN="$(dirname "$0")/tmux-ip_toggle.sh"

if [[ ! -x "$PLUGIN" ]]; then
    echo "Making plugin executable"
    chmod +x "$PLUGIN"
fi

echo "Run 1:"
"$PLUGIN"

echo -e "\nRun 2 (should toggle):"
"$PLUGIN"

echo -e "\nRun 3 (should toggle back):"
"$PLUGIN"

echo -e "\nCheck WAN cache file (if present):"
CACHE="${XDG_RUNTIME_DIR:-$HOME/.cache}/tmux_ip_toggle_state.wan"
if [[ -f "$CACHE" ]]; then
    echo "Cache contents:" && sed -n '1,2p' "$CACHE"
else
    echo "No cache file found: $CACHE"
fi
