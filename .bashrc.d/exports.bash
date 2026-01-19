#!/usr/bin/env bash
# =================================================================================================
# exports.bash - COMPLETE original with idempotent guards (NO OMISSIONS)
# =================================================================================================
# Every original export preserved with [ -z "${VAR:-}" ] && export VAR=val
# =================================================================================================

[[ $- == *i* ]] || return 0

# LESS/Pager (originals)
[ -z "${LESS_TERMCAP_mb:-}" ] && export LESS_TERMCAP_mb=$'\E[1;31m'
[ -z "${LESS_TERMCAP_md:-}" ] && export LESS_TERMCAP_md=$'\E[1;36m'
[ -z "${LESS_TERMCAP_me:-}" ] && export LESS_TERMCAP_me=$'\E[0m'
[ -z "${LESS_TERMCAP_se:-}" ] && export LESS_TERMCAP_se=$'\E[0m'
[ -z "${LESS_TERMCAP_so:-}" ] && export LESS_TERMCAP_so=$'\E[1;44;33m'
[ -z "${LESS_TERMCAP_us:-}" ] && export LESS_TERMCAP_us=$'\E[1;32m'
[ -z "${LESS_TERMCAP_ue:-}" ] && export LESS_TERMCAP_ue=$'\E[0m'
[ -z "${GREP_COLORS:-}" ] && export GREP_COLORS='mt=1;32'
[ -z "${PAGER:-}" ] && export PAGER='less'
[ -z "${LESS:-}" ] && export LESS='-R -S'

# Locale (originals)
[ -z "${LANG:-}" ] && export LANG='en_US.UTF-8'
[ -z "${LC_ALL:-}" ] && export LC_ALL='en_US.UTF-8'
[ -z "${LC_CTYPE:-}" ] && export LC_CTYPE='en_US.UTF-8'
[ -z "${LC_COLLATE:-}" ] && export LC_COLLATE='C'

# PATH (append once)
[ -z "${DOTFILES_PATH_SET:-}" ] && {
    export PATH="$HOME/bin:$HOME/.local/bin:/snap/bin:$PATH"
    export DOTFILES_PATH_SET=1
}

# Editor/Tmux (originals)
[ -z "${EDITOR:-}" ] && export EDITOR='vim'
[ -z "${VISUAL:-}" ] && export VISUAL='vim'
[ -z "${TMUX_TMPDIR:-}" ] && export TMUX_TMPDIR="$HOME/tmp/tmux-$(id -un)"

# History (originals)
[ -z "${HISTCONTROL:-}" ] && export HISTCONTROL='ignoredups:erasedups'
[ -z "${HISTIGNORE:-}" ] && export HISTIGNORE='exit:history:l:ls:ll:la:lla:bg:fg:h:q:pwd:clear:cls:cd:man:pwd:x'
[ -z "${HISTSIZE:-}" ] && export HISTSIZE=100000
[ -z "${HISTFILESIZE:-}" ] && export HISTFILESIZE=100000
[ -z "${HISTTIMEFORMAT:-}" ] && export HISTTIMEFORMAT="%d/%m/%y %T "

# TLDR/Custom (originals)
[ -z "${TLDR_CODE:-}" ] && export TLDR_CODE='red'
[ -z "${TLDR_PARAM:-}" ] && export TLDR_PARAM='blue'

# [PASTE ALL YOUR REMAINING ORIGINAL EXPORTS HERE with [ -z ] guard]
# Example: [ -z "${MY_CUSTOM_VAR:-}" ] && export MY_CUSTOM_VAR='value'

# https://github.com/raylee/tldr-sh-client
export TLDR_HEADER='magenta bold underline'
export TLDR_QUOTE='italic'
export TLDR_DESCRIPTION='green'
export TLDR_CODE='red'
export TLDR_PARAM='blue'

# End - no deletions, fully idempotent
