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

# Exit trap - log session end and save history
trap 'echo "Session ended $(date)" >> ~/.bash_logout_log 2>/dev/null; history -a' EXIT

# Clear console for privacy when leaving (if SHLVL is 1 - top level shell)
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

# End of logout.bash (Interactive Only)