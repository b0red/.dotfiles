# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

###     Determine within a startup script whether Bash is running interactively or not.
#
if [ ! -z "$PS1" ]; then
    :
    # echo " .bashrc loaded, running interactively."
else
    # If not running interactively, don't do anything
    [ -z "$PS1" ] && return
    :
    #echo ".bashrc loaded, not running interactively"
fi

# Clear away all aliases; we do this here rather than in the $ENV file shared
# between POSIX shells, because ksh relies on aliases to implement certain
# POSIX utilities, like fc(1) and type(1)
#[[ $debug -eq 1 ]] && echo Unaliasing here!; sleep 1
#unalias -a

# If ENV is set, source it to get all the POSIX-compatible interactive stuff;
# we should be able to do this even if we're running a truly ancient Bash
[ -n "$ENV" ] && . "$ENV"

###     Clear away command_not_found_handle if a system bashrc file set it up
#
unset -f command_not_found_handle

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

#   If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac


###     Set a fancy prompt (non-color, unless we know we "want" color)
#
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


###	If id command returns zero, you have root access.
#
if [ $(id -u) -eq 0 ];
    then # you are root, set red colour prompt
        PS1='\[\e[1;31m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
    else # normal
	# PS1="[\\u@\\h:\\w] $ "
        # PROMPT='\[\e[1;32m\]\u \[\e[m\]\[\e[0;32m\]@\[\e[m\]\[\e[1;32m\]\h: \w \$\[\e[m\] '
	PS1='\[\e[1;32m\]\u\[\e[m\]\[\e[0;32m\]@\h: \[\e[m\]\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
fi

###     Color manpages for 'less'
#
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
export GROFF_NO_SGR=1                  # for konsole and gnome-terminal
export PAGER='less'

###     ssh-agent
#
#ssh-add &>/dev/null || eval `ssh-agent` &>/dev/null  # start ssh-agent if not present
#[ $? -eq 0 ] && {                                     # ssh-agent has started
#ssh-add ~/.ssh/id_rsa &>/dev/null        # Load key 1
#ssh-add ~/.ssh/id_dsa &>/dev/null        # Load key 2
#}

###     Trying to run alias'es here
#
#           paused for now
#get_os
#setting_standard_commands
#
###     NOT working 4 the moment

###     Load tmux as soon as we login to shell, logout when exit tmux       
#           this fucks up tmux, can't save tmux panes layouts
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
    exec tmux
    { tmux a -t 0 || exec tmux new-session && exit; }
fi

###     Load any supplementary scripts
#       Stolen from (https://bit.ly/2slDBSV)
#
if [ -d "$HOME"/dotfiles/.bashrc.d ]; then
    for config in $HOME/dotfiles/.bashrc.d/*.bash ;
        do
            source "$config"
            #echo "file $config loaded"; sleep 1
        done
    unset -v config
fi

if [ -d "$HOME"/dotfiles/.profile.d ]; then
     for config in $HOME/dotfiles/.profile.d/*.sh;
     do
         source "$config"
         #echo "file $config loaded"; sleep 1
     done
     unset -v config
 fi

###     For getting gitstatus in tmux
#       stolen from https://github.com/drmad/tmux-git
if [[ $TMUX ]]; then source ~/.tmux/extras/tmux-git/tmux-git.sh; fi

export PATH=$PATH:/snap/bin

### Source Homeshick
#
source "$HOME/.homesick/repos/homeshick/homeshick.sh"

echo "Done!"; sleep .5; clear

