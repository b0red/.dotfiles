#!/usr/bin/env bash
# =================================================================================================
# profile.bash - Login Shell Profile Settings
# =================================================================================================
# Purpose: Settings specific to login shells (umask, PS1 defaults)
# Dependencies: None
# 
# 🔒 INTERACTIVE ONLY - This file contains:
#    - Login shell specific settings
#    - Default prompt configuration (fallback)
#    - umask settings
# 
# ⚠️ WHY GUARDED?
#    1. Login shell settings only needed interactively
#    2. umask and PS1 are for user sessions, not scripts
#    3. These settings override during login, not in subshells
# =================================================================================================

# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
[[ $- == *i* ]] || return 0

# =============================================================================
# We're in an INTERACTIVE shell - load profile settings
# =============================================================================

# Set umask (only if not already set)
[ -z "${UMASK_SET:-}" ] && {
    umask 022  # Standard secure default
    export UMASK_SET=1
}

# Basic PS1 fallback (if not set by .bashrc prompt setup)
if [[ -z "${PS1:-}" ]]; then
    if [[ $EUID -eq 0 ]]; then
        PS1='# '  # Root
    else
        PS1='\u@\h:\w\$ '  # User
    fi
fi

# PS2/PS4 prompts
export PS2='> '
export PS4='+ '

# End of profile.bash (Interactive Only)