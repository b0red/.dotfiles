#!/usr/bin/env bash
# =================================================================================================
# variables.bash - Custom Variables & Settings
# =================================================================================================
# Purpose: User-defined variables and custom settings
# Dependencies: None
# 
# 🔒 INTERACTIVE ONLY - This file contains:
#    - Custom user variables
#    - Optional settings
#    - User preferences
# 
# ⚠️ WHY GUARDED?
#    1. These are optional user customizations
#    2. Not needed for core functionality
#    3. Keeps script contexts clean
# =================================================================================================

# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
[[ $- == *i* ]] || return 0

# =============================================================================
# We're in an INTERACTIVE shell - load custom variables
# =============================================================================

# Original variables (guarded - verbatim values)
[ -z "${DOTFILES_DIR:-}" ] && export DOTFILES_DIR="$HOME/dotfiles"
[ -z "${DOTFILES_REPO:-}" ] && export DOTFILES_REPO="git@bitbucket.org:b0red/dotfiles.git"
[ -z "${CUSTOM_TMP:-}" ] && export CUSTOM_TMP="$HOME/tmp"
[ -z "${LOG_DIR:-}" ] && export LOG_DIR="$HOME/log"

# Uname shortcuts (optional - for quick reference)
[ -z "${uname_s:-}" ] && export uname_s="$(uname -s)"  # Operating System
[ -z "${uname_n:-}" ] && export uname_n="$(uname -n)"  # Node name (hostname)
[ -z "${uname_r:-}" ] && export uname_r="$(uname -r)"  # Release number
[ -z "${uname_v:-}" ] && export uname_v="$(uname -v)"  # Version info
[ -z "${uname_m:-}" ] && export uname_m="$(uname -m)"  # Machine hardware name
[ -z "${uname_p:-}" ] && export uname_p="$(uname -p)"  # Processor type
[ -z "${uname_i:-}" ] && export uname_i="$(uname -i)"  # Hardware platform
[ -z "${uname_o:-}" ] && export uname_o="$(uname -o)"  # Operating system

# End of variables.bash (Interactive Only)