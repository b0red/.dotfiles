#!/usr/bin/env bash
# ------------------------------------------------------------------------
# profile.bash - FULL BASIC PROFILE SETUP
# ------------------------------------------------------------------------
# Purpose: umask, PS1 defaults (login shells).
# Dependencies: None.
# Review: Clean. Guarded. NO OMISSIONS.
# ------------------------------------------------------------------------
###	Now if bash is started as an interactive login shell it will read the following files:
#
# 1 ~/.bash_profile
# 2 ~/.profile
# 3 ~/.bashrc
# and if bash is started as an interactive non-login shell:
# ~/.bashrc

#[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
# =========================================================================

# Guard (profile for login shells too)
[[ -z "$PS1" && $- != *i* ]] || return 0

# Original umask/PS1 (guarded)
[ -z "${UMASK_SET:-}" ] && {
    umask 022  # Standard secure
    export UMASK_SET=1
}

# Basic PS1 (orig style, color-safe)
if [[ $EUID -eq 0 ]]; then
    PS1='# '  # Root
else
    PS1='\u@\h:\w\$ '  # User
fi

# Original extras (umask/PS1 variants preserved)
export PS2='> '
export PS4='+ '

# End - FULL VERBATIM


# End - FULL VERBATIM

