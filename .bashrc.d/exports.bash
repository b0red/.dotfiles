#!/usr/bin/env bash
# =================================================================================================
# exports.bash - Environment Variable Exports
# =================================================================================================
# Purpose: Export environment variables, PATH setup, locale settings, user variables
# Dependencies: None
# 
# ⚠️ NO INTERACTIVE GUARD - Environment variables needed in all contexts
# =================================================================================================

# =============================================================================
# LESS/PAGER SETTINGS
# =============================================================================
[ -z "${LESS_TERMCAP_mb:-}" ] && export LESS_TERMCAP_mb=$'\E[1;31m'
[ -z "${LESS_TERMCAP_md:-}" ] && export LESS_TERMCAP_md=$'\E[1;36m'
[ -z "${LESS_TERMCAP_me:-}" ] && export LESS_TERMCAP_me=$'\E[0m'
[ -z "${LESS_TERMCAP_se:-}" ] && export LESS_TERMCAP_se=$'\E[0m'
[ -z "${LESS_TERMCAP_so:-}" ] && export LESS_TERMCAP_so=$'\E[1;44;33m'
[ -z "${LESS_TERMCAP_us:-}" ] && export LESS_TERMCAP_us=$'\E[1;32m'
[ -z "${LESS_TERMCAP_ue:-}" ] && export LESS_TERMCAP_ue=$'\E[0m'
[ -z "${GREP_COLORS:-}" ] && export GREP_COLORS='mt=1;32'
[ -z "${PAGER:-}" ] && {
    if command -v most >/dev/null 2>&1; then
        export PAGER='most'
    else
        export PAGER='less'
    fi
}
[ -z "${LESS:-}" ] && export LESS='-R -S'

# =============================================================================
# LOCALE SETTINGS
# =============================================================================
[ -z "${LANG:-}" ] && export LANG='en_US.UTF-8'
[ -z "${LC_ALL:-}" ] && export LC_ALL='en_US.UTF-8'
[ -z "${LC_CTYPE:-}" ] && export LC_CTYPE='en_US.UTF-8'
[ -z "${LC_COLLATE:-}" ] && export LC_COLLATE='C'

# =============================================================================
# PATH (consolidated - append once)
# =============================================================================
[ -z "${DOTFILES_PATH_SET:-}" ] && {
    export PATH="$HOME/bin:$HOME/.local/bin:/snap/bin:$HOME/.local/share/coffee/bin:$HOME/go/bin:$PATH"
    export DOTFILES_PATH_SET=1
}

# =============================================================================
# EDITOR/VISUAL
# =============================================================================
[ -z "${EDITOR:-}" ] && export EDITOR='vim'
[ -z "${VISUAL:-}" ] && export VISUAL='vim'

# =============================================================================
# TMUX TMPDIR
# =============================================================================
if [ -z "${TMUX_TMPDIR:-}" ]; then
    TMUX_TMPDIR="$HOME/tmp/tmux-$(id -un)"
    export TMUX_TMPDIR
fi

# =============================================================================
# HISTORY SETTINGS
# =============================================================================
[ -z "${HISTCONTROL:-}" ] && export HISTCONTROL='ignoredups:erasedups'
[ -z "${HISTIGNORE:-}" ] && export HISTIGNORE='exit:history:l:ls:ll:la:lla:bg:fg:h:q:pwd:clear:cls:cd:man:pwd:x:h'
[ -z "${HISTSIZE:-}" ] && export HISTSIZE=100000
[ -z "${HISTFILESIZE:-}" ] && export HISTFILESIZE=100000
[ -z "${HISTTIMEFORMAT:-}" ] && export HISTTIMEFORMAT="%d/%m/%y %T "

# =============================================================================
# TLDR SETTINGS
# =============================================================================
[ -z "${TLDR_HEADER:-}" ] && export TLDR_HEADER='magenta bold underline'
[ -z "${TLDR_QUOTE:-}" ] && export TLDR_QUOTE='italic'
[ -z "${TLDR_DESCRIPTION:-}" ] && export TLDR_DESCRIPTION='green'
[ -z "${TLDR_CODE:-}" ] && export TLDR_CODE='red'
[ -z "${TLDR_PARAM:-}" ] && export TLDR_PARAM='blue'

# =============================================================================
# USER DIRECTORIES (from variables.bash - consolidated here)
# =============================================================================
[ -z "${DOTFILES_DIR:-}" ] && export DOTFILES_DIR="$HOME/.dotfiles"
[ -z "${DOTFILES_REPO:-}" ] && export DOTFILES_REPO="git@github.com:b0red/.dotfiles.git"
[ -z "${CUSTOM_TMP:-}" ] && export CUSTOM_TMP="$HOME/tmp"
[ -z "${LOG_DIR:-}" ] && export LOG_DIR="$HOME/log"

# =============================================================================
# UNAME SHORTCUTS (all populated in one block — avoids 8 separate forks)
# =============================================================================
if [ -z "${uname_s:-}" ]; then
    uname_s="$(uname -s)"   # Operating System
    uname_n="$(uname -n)"   # Node name (hostname)
    uname_r="$(uname -r)"   # Release number
    uname_v="$(uname -v)"   # Version info
    uname_m="$(uname -m)"   # Machine hardware name
    uname_p="$(uname -p)"   # Processor type
    uname_i="$(uname -i 2>/dev/null || true)"   # Hardware platform (GNU only)
    uname_o="$(uname -o 2>/dev/null || true)"   # Operating system (GNU only)
    export uname_s uname_n uname_r uname_v uname_m uname_p uname_i uname_o
fi

# End of exports.bash

# Explicit success return
return 0 2>/dev/null || true
