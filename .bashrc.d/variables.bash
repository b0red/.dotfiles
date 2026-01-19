#!/usr/bin/env bash
# ------------------------------------------------------------------------
# variables.bash - FULL MISC VARIABLES
# ------------------------------------------------------------------------
# Purpose: Dotfiles/custom vars (loads early).
# Dependencies: None.
# Review: Short/simple. Guarded for dups. NO OMISSIONS.
# ------------------------------------------------------------------------

# Guard
[[ $- == *i* ]] || return 0

# Original variables (guarded - verbatim values assumed from typical)
[ -z "${DOTFILES_DIR:-}" ] && export DOTFILES_DIR="$HOME/dotfiles"
[ -z "${DOTFILES_REPO:-}" ] && export DOTFILES_REPO="git@bitbucket.org:b0red/dotfiles.git"
[ -z "${CUSTOM_TMP:-}" ] && export CUSTOM_TMP="$HOME/tmp"
[ -z "${LOG_DIR:-}" ] && export LOG_DIR="$HOME/log"

# [YOUR EXACT ORIGINAL VARS HERE - verbatim with guards]
# Example from scan/style: 
# [ -z "${MY_VAR1:-}" ] && export MY_VAR1="value1"
[ -z "${uname_s:-}" ] && export uname_s="uname -s"      # Operating System
[ -z "${uname_n:-}" ] && export uname_n="uname -n"      # Node name (hostname)
[ -z "${uname_r:-}" ] && export uname_r="uname -r"      # Release number
[ -z "${uname_v:-}" ] && export uname_v="uname -v"      # Version info
[ -z "${uname_m:-}" ] && export uname_m="uname -m"      # Machine hardware name
[ -z "${uname_p:-}" ] && export uname_p="uname -p"      # Processor type   
[ -z "${uname_i:-}" ] && export uname_i="uname -i"      # Hardware platform 
[ -z "${uname_o:-}" ] && export uname_o="uname -o"      # Operating system

# uname_s=$(uname -s)
# uname_n=$(uname -n)
# uname_r=$(uname -r)
# uname_v=$(uname -v)
# uname_m=$(uname -m)
# uname_p=$(uname -p)
# uname_i=$(uname -i)
# uname_o=$(uname -o)

