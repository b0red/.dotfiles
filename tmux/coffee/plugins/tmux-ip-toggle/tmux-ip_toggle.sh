#!/usr/bin/env bash
set -euo pipefail

# Small tmux plugin: toggle between WAN and local IP each run.
# STATE_FILE: where toggle state is stored. Use XDG_RUNTIME_DIR if available,
# otherwise fall back to $HOME/.cache
STATE_FILE="${XDG_RUNTIME_DIR:-$HOME/.cache}/tmux_ip_toggle_state"

mkdir -p "$(dirname "$STATE_FILE")"

# Get WAN IP (fallback to "N/A" if offline). Use short timeouts to avoid blocking tmux.
# Cache WAN lookups for a short TTL to avoid frequent external calls.
WAN_CACHE="${STATE_FILE}.wan"
WAN_TTL=600  # seconds (10 minutes for WAN lookups)
get_wan_ip() {
    # Return cached value if fresh
    if [[ -f "$WAN_CACHE" ]]; then
        cached_ts=$(sed -n '1p' "$WAN_CACHE" 2>/dev/null || echo 0)
        cached_ip=$(sed -n '2p' "$WAN_CACHE" 2>/dev/null || echo "")
        if [[ -n "$cached_ts" ]]; then
            now=$(date +%s)
            if (( now - cached_ts < WAN_TTL )); then
                printf '%s' "$cached_ip" && return 0
            fi
        fi
    fi

    ip=$(curl -4s --max-time 6 https://ifconfig.co/ip 2>/dev/null || \
         curl -4s --max-time 6 https://api.ipify.org 2>/dev/null || \
         curl -4s --max-time 6 https://ipinfo.io/ip 2>/dev/null || \
         echo "N/A")
    # store timestamp then ip on two lines
    printf '%s
%s
' "$(date +%s)" "$ip" > "$WAN_CACHE" 2>/dev/null || true
    printf '%s' "$ip"
}

# Get local IP (first non-loopback IPv4)
get_local_ip() {
    # hostname -I prints space-separated IPs; pick first non-empty
    hostname -I 2>/dev/null | awk '{print $1}' || \
    ip -4 addr show scope global 2>/dev/null | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n1 || \
    echo "127.0.0.1"
}

# Read current state (default to 'wan')
if [[ -f "$STATE_FILE" ]]; then
    STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "wan")
else
    STATE="wan"
fi

# Output and toggle without printing extra lines
if [[ "$STATE" == "wan" ]]; then
    printf "#[fg=yellow]%s#[default]" "$(get_wan_ip)"
    printf "%s" "local" > "$STATE_FILE"
else
    printf "#[fg=green]%s#[default]" "$(get_local_ip)"
    printf "%s" "wan" > "$STATE_FILE"
fi

exit 0