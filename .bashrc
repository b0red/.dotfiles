### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-27 20:42:36
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

#!/usr/bin/env bash
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-22 21:43:07
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# ~/.bashrc: executed by bash(1) for non-login shells.

# =============================================================================
# CONFIGURATION
# =============================================================================
# Loading delay (seconds) - adjust as needed
BASHRC_LOAD_DELAY=.2

# Color codes for loading feedback
LOAD_GREEN='\033[0;32m'
LOAD_RED='\033[0;31m'
LOAD_NC='\033[0m'

# =============================================================================
# LOADING FEEDBACK FUNCTION
# =============================================================================
show_loading() {
    local file="$1"
    local status="$2"  # "success" or "error"
    
    # Move cursor to upper left, clear line
    printf '\033[H\033[2K'
    
    if [[ "$status" == "success" ]]; then
        printf "${LOAD_GREEN}✓ Loading: %s${LOAD_NC}" "$file"
    else
        printf "${LOAD_RED}✗ Failed: %s${LOAD_NC}" "$file"
    fi
    
    # Small pause for visibility
    sleep "$BASHRC_LOAD_DELAY"
}

# Clear screen before loading (only in interactive mode)
if [ -n "$PS1" ]; then
    clear
fi

# =============================================================================
# EARLY EXIT CHECKS
# =============================================================================
# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# =============================================================================
# RECURSION GUARD
# =============================================================================
# Prevent infinite recursion (allow up to 3 levels for re-sourcing)
BASHRC_SOURCED=$((${BASHRC_SOURCED:-0} + 1))
[ "$BASHRC_SOURCED" -gt 3 ] && return

# Source ENV variable file if set
# shellcheck source=/dev/null
[ -n "$ENV" ] && [ -f "$ENV" ] && . "$ENV"

# =============================================================================
# DIRCOLORS SETUP
# =============================================================================
# Setup colors for 'ls' and coreutils if dircolors available
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# =============================================================================
# BASH COMPLETION
# =============================================================================
# Enable programmable completion features if not in POSIX mode
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        # shellcheck disable=SC1091
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        # shellcheck disable=SC1091
        . /etc/bash_completion
    fi
fi

# =============================================================================
# SHELL OPTIONS
# =============================================================================
shopt -s checkwinsize    # Update LINES and COLUMNS after each command
shopt -s histappend      # Append to history file, don't overwrite
shopt -s cmdhist         # Save multi-line commands as one entry
shopt -s cdspell         # Autocorrect minor spelling errors in cd
shopt -s dirspell        # Autocorrect directory names during completion
shopt -s nocaseglob      # Case-insensitive globbing

# =============================================================================
# LOAD BASHRC.D FILES
# =============================================================================
BASHRC_DIR="$HOME/dotfiles/.bashrc.d"

# Track loaded files to prevent reload dupes
declare -A loaded_files

if [[ -d "$BASHRC_DIR" ]]; then
    # =============================================================================
    # CORE FILES (NO GUARDS - must load for scripts too)
    # =============================================================================
    # These files load in BOTH interactive and non-interactive contexts
    # Order matters: exports → env → functions → pkg_aliases
    
    for file in exports.bash env.bash functions.bash pkg_aliases.bash; do
        f="$BASHRC_DIR/$file"
        if [[ -f "$f" && -z "${loaded_files[$file]:-}" ]]; then
            # shellcheck disable=SC1090
            if source "$f" 2>/dev/null; then
                loaded_files[$file]=1
                show_loading "$file" "success"
            else
                show_loading "$file" "error"
            fi
        fi
    done
    
    # =============================================================================
    # INTERACTIVE FILES (GUARDED - only for interactive shells)
    # =============================================================================
    # These files have [[ $- == *i* ]] guards and only load in interactive mode
    # docker.bash has additional check: only loads if docker is installed
    
    for file in git.bash aliases.bash colorcodes.bash; do
        f="$BASHRC_DIR/$file"
        if [[ -f "$f" && -z "${loaded_files[$file]:-}" ]]; then
            # shellcheck disable=SC1090
            if source "$f" 2>/dev/null; then
                loaded_files[$file]=1
                show_loading "$file" "success"
            else
                show_loading "$file" "error"
            fi
        fi
    done
    
    # Load docker.bash ONLY if Docker is installed
    if command -v docker >/dev/null 2>&1; then
        f="$BASHRC_DIR/docker.bash"
        if [[ -f "$f" && -z "${loaded_files[docker.bash]:-}" ]]; then
            # shellcheck disable=SC1090
            if source "$f" 2>/dev/null; then
                loaded_files[docker.bash]=1
                show_loading "docker.bash" "success"
            else
                show_loading "docker.bash" "error"
            fi
        fi
    fi
    
    # =============================================================================
    # OPTIONAL INTERACTIVE FILES (load if exist, skip if not)
    # =============================================================================
    for file in variables.bash profile.bash logout.bash; do
        f="$BASHRC_DIR/$file"
        if [[ -f "$f" && -z "${loaded_files[$file]:-}" ]]; then
            # shellcheck disable=SC1090
            if source "$f" 2>/dev/null; then
                loaded_files[$file]=1
                show_loading "$file" "success"
            fi
            # Note: No error shown if these optional files fail
        fi
    done
fi

# =============================================================================
# PROFILE.D FILES (non-bash, always load if interactive)
# =============================================================================
if [[ -d "$HOME/dotfiles/.profile.d" && $- == *i* ]]; then
    for f in "$HOME/dotfiles/.profile.d"/*.sh; do
        if [[ -f "$f" ]]; then
            basename_f=$(basename "$f")
            if [[ -z "${loaded_files[$basename_f]}" ]]; then
                # shellcheck disable=SC1090
                if source "$f" 2>/dev/null; then
                    loaded_files[$basename_f]=1
                    show_loading "$basename_f" "success"
                else
                    show_loading "$basename_f" "error"
                fi
            fi
        fi
    done
    unset -v f basename_f
fi

unset -v BASHRC_DIR loaded_files

# =============================================================================
# FINAL LOADING MESSAGE
# =============================================================================
if [ -n "$PS1" ]; then
    # Clear the loading message and show completion
    printf '\033[H\033[2K'
    echo -e "${LOAD_GREEN}✅ All dotfiles loaded${LOAD_NC}"
    sleep 0.5
    clear
fi

# =============================================================================
# PROMPT SETUP - Color-coded by privilege level
# =============================================================================
setup_prompt() {
    local is_privileged=0
    
    # Primary check: Are we actually root right now?
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        is_privileged=1
    fi
    
    # Secondary check: Is the USER variable set to root?
    if [ "$USER" = "root" ] || [ "$LOGNAME" = "root" ]; then
        is_privileged=1
    fi
    
    if [ $is_privileged -eq 1 ]; then
        # Root/privileged prompt - RED username, hostname, and $
        PS1='\[\033[1;31m\]\u\[\033[0;31m\]@\[\033[1;31m\]\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[1;31m\]\$\[\033[0m\] '
    else
        # Normal user - GREEN username, hostname, and $
        PS1='\[\033[1;32m\]\u\[\033[0;32m\]@\[\033[1;32m\]\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[1;32m\]\$\[\033[0m\] '
    fi
    
    # Export for subshells
    export PS1
}

# Set up the prompt
setup_prompt
unset -f setup_prompt

# =============================================================================
# OS DETECTION & PACKAGE MANAGER SETUP
# =============================================================================
if command -v get_os >/dev/null 2>&1; then
    get_os >/dev/null 2>&1
fi

# =============================================================================
# BROOT LAUNCHER
# =============================================================================
if command -v broot >/dev/null 2>&1; then
    [ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"
fi

# =============================================================================
# SSH AGENT & KEYCHAIN SETUP
# =============================================================================
# Only run in interactive shells AND when NOT already inside a tmux session
if [[ $- == *i* ]] && [ -z "$TMUX" ]; then

    # 1. Identify available SSH keys
    SSH_KEYS=()
    for key in id_ed25519 id_rsa id_ecdsa id_dsa; do
        [ -f "$HOME/.ssh/$key" ] && SSH_KEYS+=("$key")
    done

    # 2. Only proceed if we actually found keys
    if [ ${#SSH_KEYS[@]} -gt 0 ]; then
        
        if command -v keychain >/dev/null 2>&1; then
            # Preferred: Use keychain to manage the agent
            eval "$(keychain --eval --agents ssh --quiet "${SSH_KEYS[@]}" 2>/dev/null)"
        else
            # Fallback: Manual ssh-agent management
            if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
                eval "$(ssh-agent -s)" >/dev/null 2>&1
                for k in "${SSH_KEYS[@]}"; do
                    ssh-add "$HOME/.ssh/$k" </dev/null 2>/dev/null
                done
            fi
        fi
    fi
    
    # Cleanup variables to keep the environment clean
    unset SSH_KEYS key k
fi

# =============================================================================
# TMUX GIT INTEGRATION
# =============================================================================
if [ -f ~/.tmux-extras/tmux-git.sh ]; then 
    # shellcheck source=/dev/null
    source ~/.tmux-extras/tmux-git.sh
fi

# =============================================================================
# WELCOME MESSAGE
# =============================================================================
if [ -n "$PS1" ] && [ "$BASHRC_SOURCED" -eq 1 ]; then
    # Only show welcome on first load, not on re-source
    
    # Color definitions for welcome message
    N_GREEN='\033[0;32m'
    N_BLUE='\033[0;34m'
    if [[ -z "${NC+x}" ]]; then
        readonly NC='\033[0m'
    fi
    
    echo -e "\n${N_GREEN}Welcome to $(hostname)${NC}"
    echo -e "${N_BLUE}$(date)${NC}\n"
    unset N_GREEN N_BLUE NC
fi

# =============================================================================
# FINAL STATUS MESSAGE
# =============================================================================
#echo "✅ ~/.bashrc (re)loaded successfully (level: $BASHRC_SOURCED)"
# Added by Lazyports installer
export PATH=$PATH:/home/patrick/go/bin
