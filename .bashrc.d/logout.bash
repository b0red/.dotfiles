#!/usr/bin/env bash
# ------------------------------------------------------------------------
# logout.bash - FULL EXIT HANDLER
# ------------------------------------------------------------------------
# Purpose: Trap cleanup on exit/logout.
# Review: Simple trap. NO CHANGES NEEDED.
# ------------------------------------------------------------------------

# Guard (runs on exit anyway)
# Original trap (verbatim)
trap 'clear; echo "Session ended $(date)"; history -a' EXIT

# Alt original (if dual)
trap 'kill -TERM ${TMUX:-} 2>/dev/null; clear' DEBUG

# when leaving the console clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

