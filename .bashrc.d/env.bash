# ------------------------------------------------------------------------
#
#	.bash_environment settings
#
#  -----------------------------------------------------------------------

###	PATH
# yum
if [ -f /usr/bin/yum ]
then
	PATH=$PATH:$HOME/bin
fi


###	Pacman (ArchLinux)
if [ -f /usr/bin/pacman ]
then
	alias update='install'
	#    alias upgrade='sudo pacman -Syu'
	#    alias install='sudo pacman -Sy'
	#    alias uninstall='sudo pacman -Rs'
fi


###		APT (apt get...)
if [ -f /usr/bin/aptitude ]
then
	alias update="sudo aptitude update"
	#    alias upgrade="sudo aptitude safe-upgrade"
	#    alias install="sudo aptitude install"
	#    alias uninstall="sudo aptitude remove"
fi

###	YUM (RedHat Linux)
if [ -f /usr/bin/yum ]
then
	alias update="sudo yum update"
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
