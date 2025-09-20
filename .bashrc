# ~/.bashrc: executed by bash(1) for non-login shells.
# See /usr/share/doc/bash/examples/startup-files for examples

### Determine if Bash is running interactively
if [ -n "$PS1" ]; then
    :  # Interactive shell detected - do nothing here
else
    # If not running interactively, exit early
    return
fi

# Clear all previously defined aliases to avoid conflicts
# This is done here rather than in $ENV file because ksh uses aliases for POSIX utilities
unalias -a

# Source the ENV variable's file if set, to load POSIX-compatible interactive features
[ -n "$ENV" ] && . "$ENV"

# Remove any function 'command_not_found_handle' if defined (some system bashrc defines it)
unset -f command_not_found_handle

# Set up colors for 'ls' and other coreutils if /usr/bin/dircolors is available
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# If the shell is not interactive (does not have 'i' in $-), exit here to avoid further loading
case $- in
    *i*) ;;  # Interactive shell continues
    *) return;;
esac

### Set up a colorful prompt if the terminal supports color
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# Enable programmable completion features if not in POSIX mode
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

### Set prompt style based on user id (color red for root)
if [ "$(id -u)" -eq 0 ]; then
    # Root user prompt: bold red username, green host, blue working dir, green dollar sign
    PS1='\[\e[1;31m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
else
    # Normal user prompt: green username, green host, blue working dir, green dollar sign
    PS1='\[\e[1;32m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
fi

### Color settings for manpages viewed with less
export LESS_TERMCAP_mb=$'\E[1;31m'    # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'    # begin blink (light cyan)
export LESS_TERMCAP_me=$'\E[0m'       # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video (blue and yellow)
export LESS_TERMCAP_se=$'\E[0m'       # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'    # begin underline (green)
export LESS_TERMCAP_ue=$'\E[0m'       # reset underline
export GROFF_NO_SGR=1                 # disable SGR in groff for terminals like konsole
export PAGER='less'                   # specify pager program

### ssh-agent initialization (commented out by default)
# Uncomment and adapt if you want ssh-agent auto start and key add on login
# ssh-add &>/dev/null || eval `ssh-agent` &>/dev/null
# [ $? -eq 0 ] && {
#   ssh-add ~/.ssh/id_rsa &>/dev/null
#   ssh-add ~/.ssh/id_dsa &>/dev/null
# }

### Load tmux session on login for a specific hostname (litebook in this case)
if [[ $(uname -n) = 'litebook' ]]; then
    if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
        # Attach to existing ssh_tmux session or create it if none exists
        tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
    fi
fi

### Source supplementary scripts (modular config loading)
if [ -d "$HOME/dotfiles/.bashrc.d" ]; then
    for config in "$HOME/dotfiles/.bashrc.d"/*.bash; do
        # Source each bash config file in .bashrc.d directory
        source "$config"
    done
    unset -v config
fi

if [ -d "$HOME/dotfiles/.profile.d" ]; then
    for config in "$HOME/dotfiles/.profile.d"/*.sh; do
        # Source each shell config file in .profile.d directory
        source "$config"
    done
    unset -v config
fi

### Load tmux git status if inside tmux (for a nicer git prompt)
if [[ $TMUX ]]; then
    source ~/.tmux-git/tmux-git.sh
fi

# Add snap to PATH to use snap-installed applications easily
export PATH=$PATH:/snap/bin

### Source Homeshick if installed for dotfile management
if [ -d "$HOME/.homeshick" ]; then
    source "$HOME/.homesick/repos/homeshick/homeshick.sh"
fi

# These functions seem to be defined elsewhere, presumably in sourced scripts
# They likely detect OS and set command aliases accordingly
get_os
setting_standard_commands

### Fix tmux socket permission issues on login
umask 0022
if [ -d "/tmp/tmux-$(id -u)" ]; then
    # Try to fix permissions on tmux socket directory
    chmod 0700 "/tmp/tmux-$(id -u)" 2>/dev/null
    # If permissions still wrong, remove problematic socket directory
    if [ "$(stat -c '%a' "/tmp/tmux-$(id -u)")" != "700" ]; then
        rm -rf "/tmp/tmux-$(id -u)"
    fi
fi

### Load tmux session if none active
if [[ -z "$TMUX" ]]; then
    # Attach or create a session named 'main' on login
    tmux new-session -A -s main
fi

### Run custom tmux panes initialization script if not in tmux
if [[ -z "$TMUX" ]]; then
    ~/bin/start_tmux.sh
fi

# Evaluate keychain for managing ssh-agent keys (ensure backticks are correct)
# Original seemed to use double backticks which may cause syntax errors, changed to single:
eval $(keychain --eval --agents ssh id_rsa)

# Final messages: done, then sleep and clear screen
echo "Done!"
sleep 1
clear

# System locale settings for utf8 environment
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
