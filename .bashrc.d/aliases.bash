#-------------------------------------------------------------------------
#
#		.bash_aliases
#
#       links:
#           https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html
#-------------------------------------------------------------------------
###     Reload aliases, functions and all
#
alias reload="source ~/.bashrc"

alias nano="nano -c"
alias wget="wget -c $1"

###     Check if command exists             # Needs to be here first
#
function command_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        echo $1 is installed!
    else
        echo $1 is not installed!!
    fi
}

function command_check() {
     command -v "$1" >/dev/null 2>&1
}


###	Getting colored results when using a pipe from grep to less.
# 
alias less="less -R"

###	Jump back n directories at a time
# 
alias ..="cd .."
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"
alias ......="cd ../../../../../"

###	Various
# 
alias h="history | grep "
alias hr="history | sort -rn"
alias mv="mv -v" 
alias rm="rm -i"

### One letter quickies:
# 
alias p="pwd"
alias x="exit"

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

###     ssh
#
alias ssh='if [ "$(ssh-add -l)" = "The agent has no identities." ]; then ssh-add; fi; /usr/bin/ssh "$@"'

###	Get weeknumber
#
alias week="(/bin/date +%V)"

###	Tree
#
alias ltree="ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'"
alias tree1="tree -L 1"
alias tree2="tree -L 2"
alias tree3="tree -L 3"
alias tree4="tree -L 4"

###	File related
#
alias lf="ls -l | egrep -v '^d'"
alias ldir="ls -l | egrep '^d'"
alias clean="audo apt y"

###     Enable colorsupport of ls and add hanndy aliases
#
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)"||eval "$(dircolors -b)"
    alias ls="ls --color=auto"
    #alias grep="grep --color=auto"
    #alias fgrep="fgrep --color=auto"
    #alias egrep="egrep --color=auto"
	###     Colorize the grep command output for ease of use (good for log files)
	# 
	alias {grep,egrep,fgrep}="grep --color=always --line-number --no-messages --binary-files=without-match"
    unset GREP_OPTIONS
fi


###		Dirlistings
#
alias {kk,ll,öö}="ls -alF --group-directories-first"
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
alias tm="tmux new -s main \; split-window -h \; split-window -v -p 30 \;"
alias tmkill="tmux ls | grep : | cut -d. -f1 | awk '{print substr($1, 0, length($1)-1)}' | xargs kill"
alias tmx="tmux a -t 0"

### WIP
#   Trying to make so it's not nesting session and always starting one with a name
# session=$(uname -n); session=${session,,}; tmux new -s $session

###     Misc
#
alias latest='grep " install " /var/log/dpkg.log.1 /var/dpkg.log'
alias sshrestart="service ssh restart"
alias no_extensions='find . -type f ! -name "*.*"'
alias {module-update,modup}="git submodule foreach git pull origin master"
alias weather="curl wttr.in/stockholm"
alias comstat="push \"Command ran! (uname -n)\" || push \"Command failed!\""

###		MidnightCommande
#
if command_check mc; then alias mc="sudo mc"; fi

###     Kill all zombieprocesses
#
alias zombiekill="ps axo state,ppid | awk '!/PPID/$1~"Z"{print $2}' | xargs -r kill -9"

###     Replace cat with bat, nicer output
#   	https://github.com/sharkdp/bat/releases/download/v0.10.0/bat_0.10.0_amd64.deb; sudo dpkg -i bat_0.10.0_amd64.deb; rm -f bat*
if command_check bat; then alias cat="bat" ; fi

###     Install prettyping
#  		curl -O https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping; chmod +x prettyping; mv prettyping ~/bin
if command_check prettyping; then alias ping="prettyping --nolegend"; fi

###     Services
#
alias services="service --status-all"
alias services_run="service --status-all | grep running"

###     Docker commands
#
alias dcp="docker-compose -f ~/docker/compose/docker-compose-basic.yml "
alias dcpull="docker-compose -f ~/docker/compose/docker-compose-basic.yml pull --parallel"
alias dclogs='docker-compose -f ~/docker/compose/docker-compose-basic.yml logs -tf --tail="50" '
alias dtail='docker logs -tf --tail="50" "$@"'
alias dclean="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock zzrot/docker-clean"

###     Replace ifconfig                <----- Kanske inte funkar på LinuxMINT
#
alias ifconfig="ip -c a"

###		(https://github.com/kenorb/dotfiles/blob/master/.bash_aliases)
#		most frequent commands	
alias freq='cut -f1 -d" " ~/.bash_history | sort | uniq -c | sort -nr | head -n 30'
#		What's gobbling the memory?
alias psmem='ps -o time,ppid,pid,nice,pcpu,pmem,user,comm -A | sort -n -k 6 | tail -15'
# 		Allow to find the biggest file or directory in the current directory.
alias ds='du -ks *|sort -n'
# 		List top ten largest files/directories in current directory
alias big='du -ah . | sort -rh | head -40'
# 		List top ten largest files in current directory
alias big-files='ls -1Rhs | sed -e "s/^ *//" | grep "^[0-9]" | sort -hr | head -n40'

###		ip
#
alias ip="ip -br -c a"

###		check the status of any system service:
#
alias sstatus="sudo systemctl status"

###		restart any system service:
#
alias srestart="sudo systemctl restart"

###		List extensions
#
alias list_extensions="find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u"

###     Quick linux info
#
alias version="cat /etc/*release"   

###     Make process table searchable
#
alias psg="ps aux | grep -v grep | grep -i -e VSZ -e"

###     Show most used commands
#       not working, might need to escape " wiht \"
#alias mused="history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a; }' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n10"

###     Ports
#
alias ports='netstat -tulanp'

###     Lazydocker
if command_check lazydocker; then alias lzd="lazydocker"; fi
