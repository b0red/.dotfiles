#!/usr/bin/env bash
set -euo pipefail

# Small tmux plugin: toggle between WAN and local IP on a time-based interval.
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
    printf '%s\n%s\n' "$(date +%s)" "$ip" > "$WAN_CACHE" 2>/dev/null || true
    printf '%s' "$ip"
}

# Get local IP (first non-loopback IPv4)
get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || \
    ip -4 addr show scope global 2>/dev/null | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n1 || \
    echo "127.0.0.1"
}

# Read toggle interval from the tmux @ip_toggle_interval option (default: 300s = 5 min).
# The status bar runs this script on every status-interval tick; we only toggle
# when enough wall-clock time has passed — not on every invocation.
TOGGLE_TTL=300
if [[ -n "${TMUX:-}" ]]; then
    raw=$(tmux show-option -gqv @ip_toggle_interval 2>/dev/null || true)
    if [[ "$raw" =~ ^[0-9]+$ ]]; then
        TOGGLE_TTL=$raw
    fi
fi

# State file format (two lines): current_state \n last_toggle_timestamp
if [[ -f "$STATE_FILE" ]]; then
    STATE=$(sed -n '1p' "$STATE_FILE" 2>/dev/null || echo "wan")
    LAST_TOGGLE=$(sed -n '2p' "$STATE_FILE" 2>/dev/null || echo "0")
    # Handle old single-line format (no timestamp)
    if [[ ! "$LAST_TOGGLE" =~ ^[0-9]+$ ]]; then
        LAST_TOGGLE=0
    fi
else
    STATE="wan"
    LAST_TOGGLE=0
fi

now=$(date +%s)

# Only toggle when the interval has elapsed
if (( now - LAST_TOGGLE >= TOGGLE_TTL )); then
    if [[ "$STATE" == "wan" ]]; then
        STATE="local"
    else
        STATE="wan"
    fi
    printf '%s\n%s\n' "$STATE" "$now" > "$STATE_FILE"
else
    # Not time to toggle yet — write back the same state to keep the file valid
    printf '%s\n%s\n' "$STATE" "$LAST_TOGGLE" > "$STATE_FILE"
fi

# Output based on current state
if [[ "$STATE" == "wan" ]]; then
    printf "#[fg=yellow]%s#[default]" "$(get_wan_ip)"
else
    printf "#[fg=green]%s#[default]" "$(get_local_ip)"
fi

exit 0
