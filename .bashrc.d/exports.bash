# ------------------------------------------------------------------------
#
#   .bash_exports
#
# ------------------------------------------------------------------------

## ~/.bash_exports
# Defines environment variables and exports used by Bash.
# Typically invoked by .bashrc.

### Hosts
# File listing known remote hosts for convenience
export HOSTFILE="$HOME/.hosts"

### Enable color support for 'ls' and similar utilities if available
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
else
    export LS_COLORS=""
fi

### Default editor for command-line text editing (fallback for GUI aware editors)
export VISUAL="${VISUAL:-vim}"
export EDITOR="${EDITOR:-$VISUAL}"

### Set up PATH with personal bin directories and common system paths
# Add $HOME/bin if not already in PATH
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) PATH="$HOME/bin:$PATH" ;;
esac

# Add $HOME/binfiles if not already in PATH
case ":$PATH:" in
    *":$HOME/binfiles:"*) ;;
    *) PATH="$HOME/binfiles:$PATH" ;;
esac

# Add common system sbin and bin directories if not already present
common_paths=(/usr/local/sbin /usr/local/bin /snap/bin)
for p in "${common_paths[@]}"; do
    case ":$PATH:" in
        *":$p:"*) ;;
        *) PATH="$PATH:$p" ;;
    esac
done
export PATH

### Bash history behavior and size settings
export HISTCONTROL="ignoreboth:erasedups"  # Ignore duplicate entries and commands starting with space
export HISTIGNORE='ls:bg:fg:history:exit:clear:cls:q:pwd:* --help'  # Ignore common trivial commands
export HISTSIZE=100000
export HISTFILESIZE=100000

# Append history immediately and reload before each prompt,
# ensures history is shared across multiple shell sessions
shopt -s histappend
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a; history -c; history -r"

# Timestamp format for history entries
export HISTTIMEFORMAT="%d/%m/%y %T "

### Use compact format for bash 'time' builtin output
TIMEFORMAT='real:%lR user:%lU sys:%lS'

### Pager and manpage coloring
export PAGER="most"  # 'most' pager (may need installation)

# Colorize section titles in manpages (depends on color variable set externally)
export LESS_TERMCAP_md="${yellow:-}"

### Default blocksize for utilities like du, df
export BLOCKSIZE="M"

### Enable color output in supported environments
export CLICOLOR=1

### Perl 5 local library paths setup if perl5 local install exists
if [ -d "$HOME/perl5" ]; then
    export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5"
    export PERL_MB_OPT="--install_base $HOME/perl5"
    export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
    export PATH="$PATH:$HOME/perl5/bin"
fi

### Locale settings for US English UTF-8 with unset LC_ALL
export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
unset LC_ALL

### For tldr pager colors, if tldr installed under ~/bin
if [ -x "$HOME/bin/tldr" ]; then
    export TLDR_HEADER='magenta bold underline'
    export TLDR_QUOTE='italic'
    export TLDR_DESCRIPTION='green'
    export TLDR_CODE='red'
    export TLDR_PARAM='blue'
fi

### Environment Cleanup
# Clear deprecated or problematic options
export GREP_OPTIONS=""

### Set safer default options for utilities
export MKDIR_P_OPTS="-p"

### Extra environment variables for better coloring in macOS and others
export LSCOLORS="GxFxCxDxBxegedabagaced"
export TMUX_TMPDIR="/tmp/tmux-$UID"

readonly HOSTFILE PATH HISTCONTROL HISTIGNORE HISTSIZE HISTFILESIZE HISTTIMEFORMAT TIMEFORMAT \
         PAGER LESS_TERMCAP_md BLOCKSIZE CLICOLOR PERL_LOCAL_LIB_ROOT PERL_MB_OPT \
         PERL_MM_OPT PERL5LIB LANG LC_CTYPE TLDR_HEADER TLDR_QUOTE TLDR_DESCRIPTION \
         TLDR_CODE TLDR_PARAM GREP_OPTIONS MKDIR_P_OPTS LSCOLORS TMUX_TMPDIR
