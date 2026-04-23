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
[ -z "${PAGER:-}" ] && export PAGER='most'
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
[ -z "${TMUX_TMPDIR:-}" ] && export TMUX_TMPDIR="$HOME/tmp/tmux-$(id -un)"

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
[ -z "${DOTFILES_DIR:-}" ] && export DOTFILES_DIR="$HOME/dotfiles"
[ -z "${DOTFILES_REPO:-}" ] && export DOTFILES_REPO="git@bitbucket.org:b0red/dotfiles.git"
[ -z "${CUSTOM_TMP:-}" ] && export CUSTOM_TMP="$HOME/tmp"
[ -z "${LOG_DIR:-}" ] && export LOG_DIR="$HOME/log"

# =============================================================================
# UNAME SHORTCUTS (optional - for quick reference, from variables.bash)
# =============================================================================
# Consolidated here since they're general system info exports
[ -z "${uname_s:-}" ] && export uname_s="$(uname -s)"  # Operating System
[ -z "${uname_n:-}" ] && export uname_n="$(uname -n)"  # Node name (hostname)
[ -z "${uname_r:-}" ] && export uname_r="$(uname -r)"  # Release number
[ -z "${uname_v:-}" ] && export uname_v="$(uname -v)"  # Version info
[ -z "${uname_m:-}" ] && export uname_m="$(uname -m)"  # Machine hardware name
[ -z "${uname_p:-}" ] && export uname_p="$(uname -p)"  # Processor type
[ -z "${uname_i:-}" ] && export uname_i="$(uname -i)"  # Hardware platform
[ -z "${uname_o:-}" ] && export uname_o="$(uname -o)"  # Operating system

# End of exports.bash

# Explicit success return
return 0 2>/dev/null || true
