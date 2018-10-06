#-------------------------------------------------------------------------
#
#		.bash_aliases
#
#       Locations
#       https://remysharp.com/2018/08/23/cli-improved
#       
#-------------------------------------------------------------------------
###     Reload aliases
#
alias reload='source ~/.bashrc'

alias nano="nano -c"
alias wget="wget -c $1"

###     Check if command exists             # Needs to be here first
#
function command_exists() {
        command -v "$1" &> /dev/null
    }

###	Recursive directory listing
# 
# alias lr="ls -R | grep ':$' | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\''"

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
alias hr="history | sort -rn"
alias mv='mv -v' 
alias rm='rm -i'

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
alias su="sudo -i"
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
#
alias week="(/bin/date +%V)"


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

alias {ll,öö}="ls -alF --group-directories-first"
alias la="ls -A"
alias l="ls -CF"
alias lll="ls -alFGH --color | less -R"

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
### WIP
#   Trying to make so it's not nesting session and always starting one with a name
# session=$(uname -n); session=${session,,}; tmux new -s $session

###     Misc
#
alias latest='grep " install " /var/log/dpkg.log.1 /var/dpkg.log'
alias sshrestart='service ssh restart'
alias no_extensions='find . -type f ! -name "*.*"'
alias module-update="git submodule foreach git pull origin master"
alias weather="curl wttr.in/stockholm"
alias comstat="push \"Command ran! (uname -n)\" || push \"Command failed!\""
alias mc="sudo mc"

###     Kill all zombieprocesses
#
alias zombiekill="ps axo state,ppid | awk '!/PPID/$1~"Z"{print $2}' | xargs -r kill -9"

###     Replace cat with bat, nicer output
#
#   https://github.com/sharkdp/bat/releases/download/v0.6.0/bat-musl_0.6.0_amd64.deb; sudo dpkg -i bat; rm -f bat*
if command_exists bat; then alias cat="bat" ; fi

###     Install prettyping
#   curl -O https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping; chmod +x prettyping; mv prettyping ~/bin
# alias ping="prettyping --nolegend"
if command_exists prettyping; then alias ping="prettyping --nolegend"; fi

###     Services
#
alias services="service --status-all"
alias services_run="service --status-all | grep running"


