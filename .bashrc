### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-15 01:43:43
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

###		Prevent recursion / infinite sourcing
#
[ -n "${BASHRC_SOURCED:-}" ] && return
BASHRC_SOURCED=1

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

# User prompt: red for root, green for normal users
if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
    # Root prompt - red username and red $
    PS1='\[\033[1;31m\]\u\[\033[0;32m\]@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[1;31m\]\$\[\033[0m\] '
else
    # Normal user - green username and green $
    PS1='\[\033[1;32m\]\u\[\033[0;32m\]@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[1;32m\]\$\[\033[0m\] '
fi

# Source modular configuration files
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

# OS detection and setting package manager aliases
if command -v get_os >/dev/null 2>&1; then
    get_os >/dev/null 2>&1
    setting_standard_commands >/dev/null 2>&1
fi

# Source broot launcher if available
if command -v broot >/dev/null 2>&1; then
    [ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"
fi

# --- SSH Agent & Keychain Setup ---
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
                    ssh-add "$HOME/.ssh/$k" </dev/null
                done
            fi
        fi
    fi
    
    # Cleanup variables to keep the environment clean
    unset SSH_KEYS key k
fi
####     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# Launch the tmux script
# 1. [[ $- == *i* ]]          -> Only run in interactive terminals
# 2. [ -z "$TMUX" ]           -> Only run if NOT already inside a tmux session (prevents nesting)
# 3. [ -x "$HOME/start_tmux.sh" ] -> Only run if the file exists and is executable
if [[ $- == *i* ]] && [ -z "$TMUX" ] && [ -x "$HOME/start_tmux.sh" ]; then
    bash "$HOME/start_tmux.sh"
fi

# --- Tmux Git Integration ---
if [ -f ~/.tmux-extras/tmux-git.sh ]; then 
    source ~/.tmux-extras/tmux-git.sh
fi

# Welcome message (optional - comment out if not desired)
if [ -n "$PS1" ]; then
    clear
    echo -e "\n${GREEN:-}Welcome to $(hostname)${NC:-}"
    echo -e "${BLUE:-}$(date)${NC:-}\n"
fi

# source ~/.dcp_alias                                           # for alias="dcp vpn/novpn"

echo "✅ ~/.bashrc (re)loaded successfully"