# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# Clear all aliases to avoid conflicts
unalias -a 2>/dev/null

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

# History settings
HISTCONTROL='ignoreboth'
HISTSIZE=100000
HISTFILESIZE=100000
HISTIGNORE="exit:history:l:ls:ll:la:lla:bg:fg:h:q:pwd:clear:cls:cd:man:pwd:x"
HISTTIMEFORMAT="%d/%m/%y %T "

# User prompt: red for root, green for normal users
if [ "$(id -u)" -eq 0 ]; then
    PS1='\[\e[1;31m\]\u\[\e[m\]\[\e[0;32m\]@\h:\[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[1;31m\]\$\[\e[m\] '
else
    PS1='\[\e[1;32m\]\u\[\e[m\]\[\e[0;32m\]@\h:\[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[1;32m\]\$\[\e[m\] '
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

# tmux git integration if inside tmux
if [ -n "$TMUX" ] && [ -f "$HOME/.tmux-git/tmux-git.sh" ]; then
    source "$HOME/.tmux-git/tmux-git.sh"
fi

# OS detection and setting package manager aliases
if command -v get_os >/dev/null 2>&1; then
    get_os >/dev/null 2>&1
    setting_standard_commands >/dev/null 2>&1
fi

# Fix tmux socket permissions
umask 0022
TMUX_TMPDIR="/tmp/tmux-$(id -u)"
if [ -d "$TMUX_TMPDIR" ]; then
    chmod 0700 "$TMUX_TMPDIR" 2>/dev/null
    # Verify permissions were set correctly
    if [ "$(stat -c '%a' "$TMUX_TMPDIR" 2>/dev/null)" != "700" ]; then
        rm -rf "$TMUX_TMPDIR" 2>/dev/null
        mkdir -p "$TMUX_TMPDIR" 2>/dev/null
        chmod 0700 "$TMUX_TMPDIR" 2>/dev/null
    fi
else
    mkdir -p "$TMUX_TMPDIR" 2>/dev/null
    chmod 0700 "$TMUX_TMPDIR" 2>/dev/null
fi
unset TMUX_TMPDIR

# Source broot launcher if available
if command -v broot >/dev/null 2>&1; then
    [ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"
fi

# Start ssh-agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
fi

# SSH agent with keychain (if available)
if command -v keychain >/dev/null 2>&1; then
    # Look for SSH keys
    SSH_KEYS=()
    for key in id_ed25519 id_rsa id_ecdsa id_dsa; do
        [ -f "$HOME/.ssh/$key" ] && SSH_KEYS+=("$key")
    done
    
    # Only run keychain if we have keys
    if [ ${#SSH_KEYS[@]} -gt 0 ]; then
        eval $(keychain --eval --agents ssh --quiet "${SSH_KEYS[@]}" 2>/dev/null)
    fi
    unset SSH_KEYS key
fi

# Auto-start tmux session (disabled by default - uncomment to enable)
# Note: This creates an infinite loop if tmux is not available or fails
# Only enable if you're sure tmux is properly configured
# if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then
#     # Check if 'main' session exists
#     if tmux has-session -t main 2>/dev/null; then
#         exec tmux attach-session -t main
#     else
#         exec tmux new-session -s main
#     fi
# fi

# Run custom tmux initialization script
if [ -z "$TMUX" ] && [ -x "$HOME/bin/start_tmux.sh" ]; then
    "$HOME/bin/start_tmux.sh"
fi

# Welcome message (optional - comment out if not desired)
if [ -n "$PS1" ]; then
    echo -e "\n${GREEN:-}Welcome to $(hostname)${NC:-}"
    echo -e "${BLUE:-}$(date)${NC:-}\n"
fi

# source ~/.dcp_alias                                           # for alias="dcp vpn/novpn"

source ~/dotfiles/.bashrc
# Prevent recursion: if already sourced, exit early
if [ -f ~/.tmux-extras/tmux-gittmux-gittmux.sh ]; then source ~/.tmux-extras/tmux-gittmux-gittmux.sh; fi
