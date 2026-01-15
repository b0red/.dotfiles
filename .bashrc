### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-15 02:51:46
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

###		Prevent infinite recursion (allow up to 3 levels for re-sourcing)
#
BASHRC_SOURCED=$((${BASHRC_SOURCED:-0} + 1))
[ "$BASHRC_SOURCED" -gt 3 ] && return

# Source ENV variable file if set
[ -n "$ENV" ] && [ -f "$ENV" ] && . "$ENV"

# Setup colors for 'ls' and coreutils if dircolors available
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# Enable programmable completion features if not in POSIX mode
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Shell options
shopt -s checkwinsize    # Update LINES and COLUMNS after each command
shopt -s histappend      # Append to history file, don't overwrite
shopt -s cmdhist         # Save multi-line commands as one entry
shopt -s cdspell         # Autocorrect minor spelling errors in cd
shopt -s dirspell        # Autocorrect directory names during completion
shopt -s nocaseglob      # Case-insensitive globbing

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
    
    # Optional: Check if user is in sudo/wheel/admin group (commented out by default)
    # Uncomment if you want sudoers to also get red prompt
    # if groups 2>/dev/null | grep -qE '\b(sudo|wheel|admin)\b'; then
    #     is_privileged=1
    # fi
    
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
# SOURCE MODULAR CONFIGURATION FILES
# =============================================================================
BASHRC_DIR="$HOME/dotfiles/.bashrc.d"

if [ -d "$BASHRC_DIR" ]; then
    # Source specific files first (order matters)
    [ -f "$BASHRC_DIR/exports.bash" ] && source "$BASHRC_DIR/exports.bash"
    [ -f "$BASHRC_DIR/env.bash" ] && source "$BASHRC_DIR/env.bash"
    [ -f "$BASHRC_DIR/functions.bash" ] && source "$BASHRC_DIR/functions.bash"
    [ -f "$BASHRC_DIR/git.bash" ] && source "$BASHRC_DIR/git.bash"
    [ -f "$BASHRC_DIR/docker.bash" ] && source "$BASHRC_DIR/docker.bash"
    
    # Source any remaining .bash files not already loaded
    for f in "$BASHRC_DIR"/*.bash; do
        [ -f "$f" ] || continue
        # Skip already sourced files
        case "$(basename "$f")" in
            exports.bash|env.bash|functions.bash|git.bash|docker.bash) continue ;;
        esac
        source "$f"
    done
    unset f
fi

# Source profile scripts if they exist
if [ -d "$HOME/dotfiles/.profile.d" ]; then
    for f in "$HOME/dotfiles/.profile.d"/*.sh; do
        [ -f "$f" ] && source "$f"
    done
    unset f
fi

# Cleanup variable
unset BASHRC_DIR

# =============================================================================
# OS DETECTION & PACKAGE MANAGER SETUP
# =============================================================================
if command -v get_os >/dev/null 2>&1; then
    get_os >/dev/null 2>&1
    setting_standard_commands >/dev/null 2>&1
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
            eval $(keychain --eval --agents ssh --quiet "${SSH_KEYS[@]}" 2>/dev/null)
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

# # =============================================================================
# # TMUX AUTO-LAUNCH
# # =============================================================================
# # Launch the tmux script
# # 1. [[ $- == *i* ]]          -> Only run in interactive terminals
# # 2. [ -z "$TMUX" ]           -> Only run if NOT already inside a tmux session (prevents nesting)
# # 3. [ -x "$HOME/start_tmux.sh" ] -> Only run if the file exists and is executable
# if [[ $- == *i* ]] && [ -z "$TMUX" ] && [ -x "$HOME/start_tmux.sh" ]; then
#     bash "$HOME/start_tmux.sh"
# fi

# =============================================================================
# TMUX GIT INTEGRATION
# =============================================================================
if [ -f ~/.tmux-extras/tmux-git.sh ]; then 
    source ~/.tmux-extras/tmux-git.sh
fi

# =============================================================================
# WELCOME MESSAGE
# =============================================================================
if [ -n "$PS1" ] && [ "$BASHRC_SOURCED" -eq 1 ]; then
    # Only show welcome on first load, not on re-source
    clear
    
    # Color definitions for welcome message
    N_GREEN='\033[0;32m'
    N_BLUE='\033[0;34m'
    NC='\033[0m'
    
    echo -e "\n${N_GREEN}Welcome to $(hostname)${NC}"
    echo -e "${N_BLUE}$(date)${NC}\n"
    unset N_GREEN N_BLUE NC
fi

# # =============================================================================
# # CUSTOM ALIASES
# # =============================================================================
# # Reload bashrc easily
# alias reload='BASHRC_SOURCED=0 && source ~/.bashrc'
# alias src='source ~/.bashrc'

# Optional: Uncomment to enable DCP alias
# source ~/.dcp_alias  # for alias="dcp vpn/novpn"

# =============================================================================
# FINAL STATUS MESSAGE
# =============================================================================
echo "✅ ~/.bashrc (re)loaded successfully (level: $BASHRC_SOURCED)"