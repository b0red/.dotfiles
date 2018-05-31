# ------------------------------------------------------------------------
#
#	.bash_exports
#
# ------------------------------------------------------------------------

## ~/.bash_exports
# Define Bash exports.
# Invoked by .bashrc file.

# export LS_OPTIONS=' --color=auto'
eval "`dircolors`"

# Editor.
export EDITOR='vim'

# Path.
export PATH="$HOME/bin:$HOME/binfiles:/usr/local/sbin:/usr/local/bin:$PATH"

# Don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options.
export HISTCONTROL="ignoredups"

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1).
export HISTSIZE=10000
# Keep around 32K lines of history in file.
export HISTFILESIZE==$((1 << 15)) 

# Keep the times of the commands in history
HISTTIMEFORMAT='%F %T'

# Use a more compact format for the 'time' builtin's output.
TIMEFORMAT='real:%lR user:%lU sys:%lS'

# Perl 5.
if [ -d ~/perl5 ]; then
  export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5"
  export PERL_MB_OPT="--install_base $HOME/perl5"
  export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
  export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
  export PATH="$PATH:$HOME/perl5/bin"
fi
# Define Composer bin folder.
export COMPOSER_BIN_DIR="/usr/local/bin"

# Mule ESB configuration.
[ -d /usr/local/opt/mule ] && export MULE_HOME=/usr/local/opt/mule
[ -d "$MULE_HOME" ] && export PATH=$PATH:$MULE_HOME/bin

# Fixes for sed.
# @see: http://www.delorie.com/gnu/docs/gawk/gawk_149.html
# @see: http://stackoverflow.com/q/19242275/55075
export LANG=C
export LC_CTYPE=C 

# Set architecture flags for x64
export ARCHFLAGS="-arch x86_64"

# Configure ncurses package.
#[ -d /usr/local/opt/ncurses/bin ] \
#    && export PATH="/usr/local/opt/ncurses/bin:$PATH
#
#
