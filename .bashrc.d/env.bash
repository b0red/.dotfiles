# ------------------------------------------------------------------------
#   env.bash
#   .bash_environment settings
#   Interactive bash shell environment configuration
# ------------------------------------------------------------------------

# Return early if not an interactive shell
case $- in
    *i*) ;;
    *) return ;;
esac

# Date alias (original NOW fixed)
NOW='date +%Y-%m-%d_%H:%M'

# Check window size after each command and update LINES and COLUMNS if needed
shopt -s checkwinsize

# Save multi-line commands in history as a single entry
shopt -s cmdhist

# Enable appending history instead of overwriting
shopt -s histappend

# Additional useful shell options
shopt -s cdspell        # Autocorrect minor spelling errors in cd commands
shopt -s dirspell       # Autocorrect directory names during completion
shopt -s nocaseglob     # Case-insensitive globbing (pathname expansion)

# History settings
HISTCONTROL='ignoreboth'    # Ignore commands starting with space and duplicates
HISTSIZE=100000             # Number of commands to remember in memory
HISTFILESIZE=100000         # Number of lines in the history file   
HISTIGNORE="exit:history:l:ls:ll:la:lla:bg:fg:h:q:pwd:clear:cls:cd:man:pwd:x"
HISTTIMEFORMAT="%d/%m/%y %T "

# Enable lesspipe for friendly less behavior if available
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# Detect color support
force_color_prompt=yes

# Set PS1 prompt with color support and root detection
if [[ "$color_prompt" == yes ]]; then
    # Check if running as root
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        # Root prompt - RED username and dollar sign
        PS1='${debian_chroot:+($debian_chroot)}\[\033[1;31m\]\u\[\033[0;32m\]@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[1;31m\]\$\[\033[0m\] '
    else
        # Normal user - GREEN username and dollar sign
        PS1='${debian_chroot:+($debian_chroot)}\[\033[1;32m\]\u\[\033[0;32m\]@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[1;32m\]\$\[\033[0m\] '
    fi
else
    # Plain prompt without colors
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w# '  # Root gets #
    else
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '  # User gets $
    fi
fi

# Set xterm title to user@host:dir if supported
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

unset color_prompt force_color_prompt
    
# Enable colored ls output if supported
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# Set default editor
export EDITOR=vim
export VISUAL=vim

# Less options for better paging
export LESS='-R -M -i -j10'  # -R=colors, -M=verbose prompt, -i=ignore case, -j10=jump target

# Locale settings (uncomment and adjust if needed)
# export LANG=en_US.UTF-8
# export LC_ALL=en_US.UTF-8

# Debugging aid: uncomment to check if this file is loaded
# echo "Loaded: ${BASH_SOURCE##*/}"