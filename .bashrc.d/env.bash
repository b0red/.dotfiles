# ------------------------------------------------------------------------
#
#	.bash_environment settings
#
#  -----------------------------------------------------------------------

###     PATH
###     YUM (RedHat Linux)
#
if [ -f /usr/bin/yum ]
then
	PATH=$PATH:$HOME/bin
    alias install="sudo yum install -y" $1
    alias uninstall="sudo yum remove" $1
    alias update="sudo yum update -y"
    alias upgrade="sudo yum upgrade -y"
fi

###     DNF Fedorah
#
if [ -f /usr/bin/dnf ]
then
    alias upgrade="dnf upgrade"
    alias install="dnf install" $1
    alias uninstall="dnf remove" $1
    alias search="dnf search" $1
    alias autoremove="dnf remove" $1
    alias clean="dnf clean all"
fi

###	    Pacman (ArchLinux)
#
if [ -f /usr/bin/pacman ]
then
	alias update='pacman -Syu' $1
    alias install="pacman -S" $1
    alias force_install="pacman -S --force" $1
    alias uninstall="pacman -Rs" $1
    #    alias upgrade='sudo pacman -Syu'
	#    alias install='sudo pacman -Sy'
	#    alias uninstall='sudo pacman -Rs'
fi


###		APT (apt get...)
#
if [ -f /usr/bin/apt* ]
then
	alias apt_update="sudo aptitude update"
    alias update="sudo apt-get update && sudo apt-get upgrade"
    alias install="sudo apt install $1"
    alias uninstall="sudo apt remove $1"
    alias clean="sudp apt clean; sudo apt autoremove; sudo apt purge"
fi

### 	Zypper (opensuse, fedora)
#
if [ -f /usr/bin/yum ]
then
	alias app_search="zypper search" $1
    alias install="zypper install" $1
    alias uninstall="zypper remove" $1
    alias update="sudo zypper refresh; sudo zypper dup"
    #    alias upgrade="sudo yum safe-upgrade"
	#    alias install="sudo yum install"
	#    alias uninstall="sudo yum remove"
fi

###     Freebsd)
#
if [ -f /usr/bin/yum ]
then
    alias app_search="zypper search" $1
    alias install="zypper install" $1
    alias uninstall="zypper remove" $1
    alias update="sudo zypper refresh; sudo zypper dup"
    #    alias upgrade="sudo yum safe-upgrade"
    #    alias install="sudo yum install"
    #    alias uninstall="sudo yum remove"
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

###	Avoid duplicates in the bash command history. And ignore commands with leading space.
#	(IGNORESPACE AND IGNOREDUPE)
HISTCONTROL=ignoreboth

###	Ignore certain commands in histor
#
HISTIGNORE='ls:bg:fg:history:exit:clear:cls:q:pwd:* --help'


###	Record timestamps in history
#
HISTTIMEFORMAT='%F %T '

###	One command per line n history
#
shopt -s cmdhist

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
#
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

###	Append to the history file, don't overwrite it
#
shopt -s histappend

###	Make new shells get the history lines from all previous
# 	shells instead of the default "last window closed" history.
#
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

###	Allow a larger history file
#
HISTFILESIZE=1000000
HISTSIZE=1000000

# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";


################################################################################
#
#		Ubuntu (debian specific?)
#
################################################################################


###	Set a fancy prompt (non-color, unless we know we "want" color)
#
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

###	Make less more friendly for non-text input files, see lesspipe(1)
#
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

###	Set variable identifying the chroot you work in (used in the prompt below)
#
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

####	If not running interactively, don't do anything
#
case $- in
	*i*) ;;
    *) return;;
esac

# Uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
	xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

###     Just to check if loaded
#
# echo ${file##*/}
