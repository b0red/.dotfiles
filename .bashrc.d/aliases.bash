#-------------------------------------------------------------------------
#
#		.bash_aliases
#
#-------------------------------------------------------------------------
###     Reload aliases
#
alias reload='source ~/.bashrc'

alias nano="nano -c"
alias wget="wget -c $1"

###	Recursive directory listing
# 
alias lr="ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\''"

###	Getting colored results when using a pipe from grep to less.
# 
alias less='less -R'

###	Jump back n directories at a time
# 
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'

###	Various
# 
alias h='history | grep '
alias mv='mv -v' 
alias rm='rm -v'

###	One letter quickies:
# 
alias p='pwd'
alias x='exit'

###	tmux to connect to existing session or create a new
# 
#alias tmux="tmux new-session -A -d -s main"

###	Nicer directory listings
# 
alias clr="clear;pwd;ls"
alias cls="clear"
alias lsd"=ls -alF |grep /$" 	## Might be wrong
alias back="cd $OLDPWD"

###	Rootstuf
# 
alias root="sudo su"
alias su="sudo -l"
alias f="find . | grep "

###	Dirsize in human readable form
# 
alias df="df -h"

###     Colorize the grep command output for ease of use (good for log files)
# 
alias {grep,egrep,fgrep}="grep --color=always --line-number --no-messages --binary-files=without-match"

###     ssh
#
alias ssh='if [ "$(ssh-add -l)" = "The agent has no identities." ]; then ssh-add; fi; /usr/bin/ssh "$@"'


###	Get weeknumber
alias week="date +V%"


###	Tree
#
alias tree1="tree -L 1"
alias tree2="tree -L 2"
alias tree3="tree -L 3"
alias tree4="tree -L 4"

###	File related
#
alias lf="ls -l | egrep -v '^d'"
alias ldir="ls -l | egrep '^d'"
alias update="sudo apt-get update && sudo apt-get upgrade"
alias install="sudo apt install $1"
alias uninstall="sudo apt remove $1"
alias clean="audo apt y"

###     Enable colorsupport of ls and add hanndy aliases
#
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)"||eval "$(dircolors -b)"
    alias ls="ls --color=auto"
    alias grep="grep --color=auto"
    alias fgrep="fgrep --color=auto"
    alias egrep="egrep --color=auto"
    unset GREP_OPTIONS
fi

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias lll="ls -alFGH --color | less -R"

###     Add an alert alias for long running commands. Use liek:
# sleep 10; alert
#alias alert ='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

###     Replace top, du, df
#
alias top="htop"
alias du="ncdu"
alias df="pydf"
alias psg="ps aux | grep -v grep | grep -i -e VSZ -e"

###     TMUX
#
alias tm=":tmux new -s main \; split-window -h \; split-window -v -p 30 \;"
alias tmkill="tmux ls | grep : | cut -d. -f1 | awk '{print substr($1, 0, length($1)-1)}' | xargs kill"

###     Misc
#
alias latest='grep " install " /var/log/dpkg.log.1 /var/dpkg.log'
alias sshrestart='service ssh restart'

