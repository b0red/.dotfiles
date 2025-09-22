# ------------------------------------------------------------------------
#
#   .bash_exports
#
# Environment variable exports with protections against readonly errors.
# This file defines shell environment variables only.
#
# Export only if not already declared or readonly to avoid errors when re-sourcing.
# ------------------------------------------------------------------------

# Helper function to export variables safely
export_if_unset() {
    local var_name="$1"
    local var_value="$2"
    
    # Check if variable is already declared and not readonly
    if ! declare -p "$var_name" &>/dev/null || ! declare -p "$var_name" | grep -q "^declare -r"; then
        export "$var_name=$var_value"
    fi
}

# Hosts file used by some scripts for easy hostname lookup
export_if_unset HOSTFILE "$HOME/.hosts"

# Enable color support for 'ls' and other commands with dircolors
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
else
    export LS_COLORS=""
fi

# Default editor for command line use
export_if_unset VISUAL "${VISUAL:-vim}"
export_if_unset EDITOR "${VISUAL:-vim}"

# Add user bin directories to PATH if not already present
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) export PATH="$HOME/bin:$PATH" ;;
esac
case ":$PATH:" in
    *":$HOME/binfiles:"*) ;;
    *) export PATH="$HOME/binfiles:$PATH" ;;
esac

# Add common system paths to PATH if missing
common_paths=(/usr/local/sbin /usr/local/bin /snap/bin)
for p in "${common_paths[@]}"; do
    case ":$PATH:" in
        *":$p:"*) ;;
        *) export PATH="$PATH:$p" ;;
    esac
done

# Large shell history size
export_if_unset HISTSIZE 100000
export_if_unset HISTFILESIZE 100000

# Immediate history append and reload for shared shell history
shopt -s histappend
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a; history -c; history -r"

# Time format for history entries
export_if_unset HISTTIMEFORMAT "%d/%m/%y %T "

# Compact timing format for bash builtin time
export_if_unset TIMEFORMAT 'real:%lR user:%lU sys:%lS'

# LESS pager coloring (bold)
export_if_unset LESS_TERMCAP_md $'\E[1;36m'

# Utilities block size unit (Mega)
export_if_unset BLOCKSIZE "M"

# Enable color output for commands supporting it
export_if_unset CLICOLOR 1

# Perl local library paths in case of custom perl installs
if [ -d "$HOME/perl5" ]; then
    export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5"
    export PERL_MB_OPT="--install_base $HOME/perl5"
    export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
    export PATH="$PATH:$HOME/perl5/bin"
fi

# Locale settings for consistent UTF-8 environment
export_if_unset LANG "en_US.UTF-8"
# LC_CTYPE is often readonly, so we avoid setting it.
# export_if_unset LC_CTYPE "en_US.UTF-8"
unset LC_ALL

# TLDR colors for pretty man-like output, if tldr installed
if [ -x "$HOME/bin/tldr" ]; then
    export_if_unset TLDR_HEADER 'magenta bold underline'
    export_if_unset TLDR_QUOTE 'italic'
    export_if_unset TLDR_DESCRIPTION 'green'
    export_if_unset TLDR_CODE 'red'
    export_if_unset TLDR_PARAM 'blue'
fi

# Options for mkdir default -p behavior
export_if_unset MKDIR_P_OPTS "-p"

# Colors for macOS and similar systems
export_if_unset LSCOLORS "GxFxCxDxBxegedabagaced"

# Tmp directory for tmux sockets, unique per user
export_if_unset TMUX_TMPDIR "/tmp/tmux-$UID"