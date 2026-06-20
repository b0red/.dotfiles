#!/usr/bin/env bash
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by run_me_first.sh 2026-06-21 00:37:20
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

###     WSL-Specific: Proper Loading Order (add to ~/.bash_profile if exists, or create):
#

# ------------------------------------------------
# Skip source'ing .bashrc in tmux (recommended)
export BASHRC_SKIP_IN_TMUX="no"

# # OR: Always load in tmux
# export BASHRC_SKIP_IN_TMUX="no"

# # OR: Ask mode
# export BASHRC_SKIP_IN_TMUX="ask"
# ------------------------------------------------

# ~/.bash_profile: Load .bashrc for non-login shells
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# shellcheck disable=SC1091
[ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
