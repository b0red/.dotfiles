# ~/.bashrc: executed by bash(1) for non-login shells.

# Interactive shell check
if [ -n "$PS1" ]; then
    :  # continue
else
    return
fi

# Clear all aliases to avoid conflicts
unalias -a

# Source ENV variable file if set
[ -n "$ENV" ] && . "$ENV"

# Remove command_not_found_handle function if defined
# This is often readonly, so we avoid trying to unset it.
# unset -f command_not_found_handle

# Setup colors for 'ls' and coreutils if dircolors available
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# If shell not interactive exit early
case $- in
    *i*) ;;
    *) return;;
esac

# Set colorful prompt if terminal supports color
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
    *) color_prompt= ;;
esac

# Enable programmable completion features if not in POSIX mode
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# User prompt: red for root, green for normal users
if [ "$(id -u)" -eq 0 ]; then
    PS1='\[\e[1;31m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
else
    PS1='\[\e[1;32m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
fi

# Source environment exports and other modular configs
[ -f "$HOME/dotfiles/.bashrc.d/.bash_exports" ] && source "$HOME/dotfiles/.bashrc.d/.bash_exports"
[ -f "$HOME/dotfiles/.bashrc.d/.bash_functions" ] && source "$HOME/dotfiles/.bashrc.d/.bash_functions"
[ -f "$HOME/dotfiles/.bashrc.d/.git_aliases" ] && source "$HOME/dotfiles/.bashrc.d/.git_aliases"
[ -f "$HOME/dotfiles/.bashrc.d/docker.bash" ] && source "$HOME/dotfiles/.bashrc.d/docker.bash"

# Source additional bash scripts ending with .bash
if [ -d "$HOME/dotfiles/.bashrc.d" ]; then
    for f in "$HOME/dotfiles/.bashrc.d"/*.bash; do
        source "$f"
    done
    unset -v f
fi

# Source profile scripts if they exist
if [ -d "$HOME/dotfiles/.profile.d" ]; then
    for f in "$HOME/dotfiles/.profile.d"/*.sh; do
        source "$f"
    done
    unset -v f
fi

# tmux git integration if inside tmux
[[ $TMUX ]] && [ -f "$HOME/.tmux-git/tmux-git.sh" ] && source "$HOME/.tmux-git/tmux-git.sh"

# OS detection and setting aliases
get_os
setting_standard_commands

# Fix tmux socket permissions
umask 0022
if [ -d "/tmp/tmux-$(id -u)" ]; then
    chmod 0700 "/tmp/tmux-$(id -u)" 2>/dev/null
    if [ "$(stat -c '%a' "/tmp/tmux-$(id -u)")" != "700" ]; then
        rm -rf "/tmp/tmux-$(id -u)"
    fi
fi

# Load or attach tmux named main if not running inside tmux
if [[ -z "$TMUX" ]]; then
    tmux new-session -A -s main
fi

# Run tmux panes init script if present and not in tmux
if [[ -z "$TMUX" ]]; then
    [ -x "$HOME/bin/start_tmux.sh" ] && "$HOME/bin/start_tmux.sh"
fi

# Evaluate keychain ssh-agent keys
eval $(keychain --eval --agents ssh id_rsa)

echo "Done!"
sleep 1
clear