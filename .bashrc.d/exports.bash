# ------------------------------------------------------------------------
#   exports.bash
#   Environment variable exports with protections against readonly errors
#   This file defines shell environment variables only
# ------------------------------------------------------------------------

# Helper function to export variables safely
export_if_unset() {
    local var_name="$1"
    local var_value="$2"
    
    # Check if variable is readonly
    if declare -p "$var_name" &>/dev/null && declare -p "$var_name" 2>/dev/null | grep -q "^declare -[^ ]*r"; then
        return 0  # Skip readonly variables
    fi
    
    # Export if unset or not readonly
    export "$var_name=$var_value"
}

# Hosts file used by some scripts for easy hostname lookup
export_if_unset HOSTFILE "$HOME/.hosts"

# Default editor for command line use
export_if_unset VISUAL "vim"
export_if_unset EDITOR "$VISUAL"

# Enable color support for 'ls' and other commands with dircolors
if command -v dircolors >/dev/null 2>&1; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
    export_if_unset LS_COLORS "$LS_COLORS"
else
    export_if_unset LS_COLORS ""
fi

# Add user bin directories to PATH if not already present
add_to_path() {
    local dir="$1"
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

add_to_path "$HOME/bin"
add_to_path "$HOME/binfiles"
add_to_path "$HOME/.local/bin"

# Add common system paths to end of PATH if missing
append_to_path() {
    local dir="$1"
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$PATH:$dir"
    fi
}

append_to_path "/usr/local/sbin"
append_to_path "/usr/local/bin"
append_to_path "/snap/bin"

# History settings
export_if_unset HISTSIZE 100000
export_if_unset HISTFILESIZE 100000
export_if_unset HISTTIMEFORMAT "%d/%m/%y %T "

# Enable immediate history append and reload for shared shell history
if ! shopt -q histappend 2>/dev/null; then
    shopt -s histappend 2>/dev/null
fi

# Append history command to PROMPT_COMMAND safely
if [[ ! "$PROMPT_COMMAND" =~ "history -a" ]]; then
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a; history -c; history -r"
fi

# Compact timing format for bash builtin time
export_if_unset TIMEFORMAT 'real:%lR user:%lU sys:%lS'

# LESS pager settings and colors
export_if_unset LESS '-R -M -i -j10'
export_if_unset LESS_TERMCAP_mb $'\E[1;31m'     # begin blinking
export_if_unset LESS_TERMCAP_md $'\E[1;36m'     # begin bold
export_if_unset LESS_TERMCAP_me $'\E[0m'        # end mode
export_if_unset LESS_TERMCAP_se $'\E[0m'        # end standout-mode
export_if_unset LESS_TERMCAP_so $'\E[1;33m'     # begin standout-mode
export_if_unset LESS_TERMCAP_ue $'\E[0m'        # end underline
export_if_unset LESS_TERMCAP_us $'\E[1;32m'     # begin underline

# Utilities block size unit (Mega)
export_if_unset BLOCKSIZE "M"

# Enable color output for commands supporting it
export_if_unset CLICOLOR 1

# Colors for macOS and BSD ls
export_if_unset LSCOLORS "GxFxCxDxBxegedabagaced"

# Perl local library paths in case of custom perl installs
if [[ -d "$HOME/perl5" ]]; then
    export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:$PERL_LOCAL_LIB_ROOT}"
    export PERL_MB_OPT="--install_base $HOME/perl5"
    export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
    append_to_path "$HOME/perl5/bin"
fi

# Locale settings for consistent UTF-8 environment
export_if_unset LANG "en_US.UTF-8"
export_if_unset LC_ALL "en_US.UTF-8"

# TLDR colors for pretty man-like output, if tldr installed
if command -v tldr >/dev/null 2>&1 || [[ -x "$HOME/bin/tldr" ]]; then
    export_if_unset TLDR_HEADER 'magenta bold underline'
    export_if_unset TLDR_QUOTE 'italic'
    export_if_unset TLDR_DESCRIPTION 'green'
    export_if_unset TLDR_CODE 'red'
    export_if_unset TLDR_PARAM 'blue'
fi

# Tmp directory for tmux sockets, unique per user
export_if_unset TMUX_TMPDIR "/tmp/tmux-$UID"

# Create tmux tmp directory if it doesn't exist
[[ ! -d "$TMUX_TMPDIR" ]] && mkdir -p "$TMUX_TMPDIR" 2>/dev/null

# Ignore list for fif in functions.bash
# Comma-separated lists
export FIF_IGNORE_DIRS=".git,.svn,node_modules,dist,build"
export FIF_IGNORE_FILES="*.min.js,*.lock"

# Cleanup helper functions
unset -f export_if_unset add_to_path append_to_path