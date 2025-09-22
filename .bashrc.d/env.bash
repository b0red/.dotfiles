# ------------------------------------------------------------------------
#   env.bash
#   .bash_environment settings
#   POSIX compatible settings for interactive bash and ksh shells
# ------------------------------------------------------------------------

# Check window size after each command and update LINES and COLUMNS if needed
shopt -s checkwinsize

# Save multi-line commands in history as a single entry
shopt -s cmdhist

# Enable appending history instead of overwriting
shopt -s histappend

# HISTIGNORE is often readonly, so we avoid setting it.
# Ignore common trivial commands in history

# Ignore commands starting with space, and duplicates
HISTCONTROL='ignoreboth'
HISTIGNORE="exit:history:l:l[1als]:lla:+(.):ls:bg:fg:h:q:pwd:clear:cls:cd:kk:man"

# Set colored prompt support for xterm-color terminals
case "$TERM" in
    xterm-color) color_prompt=yes ;;
    *) color_prompt= ;;
esac

# Enable lesspipe for friendly less behavior if available
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# Return if not an interactive shell
case $- in
    *i*) ;;
    *) return ;;
esac

# Force colored prompt unless terminal lacks support
force_color_prompt=yes

if [[ -n "$force_color_prompt" ]] && command -v tput >/dev/null 2>&1 && tput setaf 1 >&/dev/null; then
    color_prompt=yes
else
    color_prompt=
fi

# Set PS1 prompt string with or without colors accordingly
if [[ "$color_prompt" == yes ]]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Set xterm title to user@host:dir if supported
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
esac

# Debugging aid: uncomment to check if this file is loaded
# echo ${file##*/}
