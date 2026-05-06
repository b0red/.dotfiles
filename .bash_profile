#!/usr/bin/env bash
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-05-05 23:40:36
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

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
source $HOME/.config/broot/launcher/bash/br

. "$HOME/.cargo/env"
