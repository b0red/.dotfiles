# ~/.bashrc: executed by bash(1) for non-login shells.
# See /usr/share/doc/bash/examples/startup-files for examples

# Interactive check
if [ -n "$PS1" ]; then
    :  # continue
else
    return
fi

unalias -a  # clear aliases

[ -n "$ENV" ] && . "$ENV"

unset -f command_not_found_handle

if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

case $- in
    *i*) ;;
    *) return;;
esac

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
    *) color_prompt= ;;
esac

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

if [ "$(id -u)" -eq 0 ]; then
    PS1='\[\e[1;31m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
else
    PS1='\[\e[1;32m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
fi

export LESS_TERMCAP_mb=$'\E[1;31m'
export LESS_TERMCAP_md=$'\E[1;36m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_us=$'\E[1;32m'
export LESS_TERMCAP_ue=$'\E[0m'
export GROFF_NO_SGR=1
export PAGER='less'

# ssh-agent example (commented)
# ssh-add &>/dev/null || eval `ssh-agent` &>/dev/null

if [[ $(uname -n) == 'litebook' ]]; then
    if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
        tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
    fi
fi

# Source modular configs:
[ -f "$HOME/dotfiles/.bash_exports" ] && source "$HOME/dotfiles/.bash_exports"
[ -f "$HOME/dotfiles/.bash_functions" ] && source "$HOME/dotfiles/.bash_functions"
[ -f "$HOME/dotfiles/.git_aliases" ] && source "$HOME/dotfiles/.git_aliases"
[ -f "$HOME/dotfiles/docker.bash" ] && source "$HOME/dotfiles/docker.bash"

if [ -d "$HOME/dotfiles/.bashrc.d" ]; then
    for f in "$HOME/dotfiles/.bashrc.d"/*.bash; do
        source "$f"
    done
    unset -v f
fi

if [ -d "$HOME/dotfiles/.profile.d" ]; then
    for f in "$HOME/dotfiles/.profile.d"/*.sh; do
        source "$f"
    done
    unset -v f
fi

if [[ $TMUX ]]; then
    [ -f "$HOME/.tmux-git/tmux-git.sh" ] && source "$HOME/.tmux-git/tmux-git.sh"
fi

export PATH="$PATH:/snap/bin"

if [ -d "$HOME/.homeshick" ]; then
    source "$HOME/.homesick/repos/homeshick/homeshick.sh"
fi

get_os
setting_standard_commands

umask 0022
if [ -d "/tmp/tmux-$(id -u)" ]; then
    chmod 0700 "/tmp/tmux-$(id -u)" 2>/dev/null
    if [ "$(stat -c '%a' "/tmp/tmux-$(id -u)")" != "700" ]; then
        rm -rf "/tmp/tmux-$(id -u)"
    fi
fi

if [[ -z "$TMUX" ]]; then
    tmux new-session -A -s main
fi

if [[ -z "$TMUX" ]]; then
    [ -x "$HOME/bin/start_tmux.sh" ] && "$HOME/bin/start_tmux.sh"
fi

eval $(keychain --eval --agents ssh id_rsa)

echo "Done!"
sleep 1
clear

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
