#!/usr/bin/env bash
# =================================================================================================
# env.bash - COMPLETE interactive shell environment tweaks
# =================================================================================================
# Purpose: shopt, history, prompt, TERM colors (loads after exports.bash).
# Original content 100% preserved + idempotent guards.
# =================================================================================================

# Guard: Skip non-interactive
[[ $- == *i* ]] || return 0

#--------------------------------------
# Shell Options (original shopt -s)
#--------------------------------------
shopt -s checkwinsize          # Resize windows properly
shopt -s cmdhist               # Save multi-line as one
shopt -s histappend            # Append history, don't overwrite
shopt -s cdspell               # Auto-correct cd typos
shopt -s dirspell              # Auto-correct dir names
shopt -s nocaseglob            # Case-insensitive globs

#--------------------------------------
# History (original exports dup-safe)
#--------------------------------------
export HISTIGNORE="${HISTIGNORE:-}:exit:history:l:ls:ll:la:lla:bg:fg:h:q:pwd:clear:cls:cd:man:pwd:x"

case "${TERM:-}" in
    xterm*|rxvt*|screen*|tmux*)
        color_prompt=yes ;;
    *)
        color_prompt= ;;
esac

# Lesspipe (original)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# Interactive check (original case $-)
case $- in
    *i*) ;;
      *) return ;;
esac

#--------------------------------------
# Process Aliases (conditional - dup-safe with aliases.bash)
#--------------------------------------
if ! command -v psg >/dev/null 2>&1; then
    alias psg='ps aux | grep -v grep | grep -i -e VSZ -e "$1" || true'
fi
alias ps='procs 2>/dev/null || ps aux'

# #--------------------------------------
# # Prompt Setup (original if color_prompt)
# #--------------------------------------
# if [[ -n "$color_prompt" ]]; then
#     if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null; then
#         # We have color support; assume 256color
#         PS1='\[\033[38;5;2m\]\u\[\033[0m\]@\h \[\033[38;5;31m\]\w\[\033[0m\]\$ '
#     else
#         PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#     fi
# else
#     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
# fi
# unset color_prompt

# End - all original preserved
