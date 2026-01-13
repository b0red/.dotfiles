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

if [[ -n "$force_color_prompt" ]]; then
    if command -v tput >/dev/null 2>&1; then
        # Test if terminal supports colors
        if tput setaf 1 &>/dev/null; then
            color_prompt=yes
        else
            color_prompt=
        fi
    else
        color_prompt=
    fi
fi

# Set PS1 prompt string with or without colors
if [[ "$color_prompt" == yes ]]; then
    # Colored prompt: user@host:path$
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    # Plain prompt
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
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