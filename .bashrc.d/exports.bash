# ------------------------------------------------------------------------
#
#	.bash_exports
#
# ------------------------------------------------------------------------

## ~/.bash_exports
# Define Bash exports.
# Invoked by .bashrc file.

###	Hosts
#	puts a list of remote hosts in ~/.hosts
export HOSTFILE=$HOME/.hosts

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
export HISTSIZE=100000

# Keep around 32K lines of history in file.
export HISTFILESIZE=100000

# Keep the times of the commands in history
export HISTTIMEFORMAT="%d/%m/%y %T "

# Use a more compact format for the 'time' builtin's output.
TIMEFORMAT='real:%lR user:%lU sys:%lS'

# Make new shells get the history lines from all previous
# shells instead of the default "last window closed" history
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

###	Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

BLOCKSIZE=M
export BLOCKSIZE
CLICOLOR=1

### 	Perl 5.
if [ -d ~/perl5 ]; then
  export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5"
  export PERL_MB_OPT="--install_base $HOME/perl5"
  export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
  export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
  export PATH="$PATH:$HOME/perl5/bin"
fi

###	Prefer US English and use UTF_8 encoding
export LANG="en_US"
export LC_ALL="en_US.UTF-8"
