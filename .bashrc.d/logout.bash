#!/usr/bin/env bash
# =================================================================================================
# logout.bash - Session Cleanup & Exit Handlers
# =================================================================================================
# Purpose: Cleanup operations when exiting shell sessions
# Dependencies: None
# 
# 🔒 INTERACTIVE ONLY - This file contains:
#    - Exit traps for cleanup
#    - Session end logging
#    - Screen clearing on exit
# 
# ⚠️ WHY GUARDED?
#    1. Exit handlers only relevant for interactive sessions
#    2. Scripts should control their own cleanup
#    3. Console clearing for privacy only needed in user sessions
# =================================================================================================

# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
[[ $- == *i* ]] || return 0

# =============================================================================
# We're in an INTERACTIVE shell - set up logout handlers
# =============================================================================

# Max lines to keep in the logout log (easy to change)
LOGOUT_LOG_MAX_LINES=50
LOGOUT_LOG="$HOME/.bash_logout_log"

_logout_handler() {
    echo "Session ended $(date)" >> "$LOGOUT_LOG" 2>/dev/null
    history -a
    # Rotate log: keep only the last N lines
    if [ -f "$LOGOUT_LOG" ]; then
        local tmp="${LOGOUT_LOG}.tmp"
        if tail -n "$LOGOUT_LOG_MAX_LINES" "$LOGOUT_LOG" > "$tmp" 2>/dev/null; then
            mv "$tmp" "$LOGOUT_LOG" 2>/dev/null
        else
            rm -f "$tmp" 2>/dev/null
        fi
    fi
}

trap '_logout_handler' EXIT

# Clear console for privacy when leaving (if SHLVL is 1 - top level shell)
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

# End of logout.bash (Interactive Only)