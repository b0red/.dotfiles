### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-21 21:58:24
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

###		Prevent recursion
#
[ -n "${PROFILE_SOURCED:-}" ] && return
PROFILE_SOURCED=1

###     if running bash
#
if [ -n "$BASH_VERSION" ]; then
	# include .bashrc if it exists
	if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
	fi
fi

###     set PATH so it includes user's private bin dir if it exists
#
if [ -d "$HOME/bin" ]; then 
	PATH="$HOME/bin:$PATH"
fi

###     Load any supplementary scripts in $HOME/.profile.d directory
#
if [ -d $HOME/dotfiles/.profile.d ]; then
	for config in "$HOME"/dotfiles/.profile.d/*.sh ; do
	. "$config"
	#echo $config loaded.
	done
	unset -v config
fi

###     Check if .cargo exists, then add to path
#
if [ -d "$HOME"/.cargo ]; then
	export PATH="$HOME/.cargo/bin:$PATH"
fi

### Add Go binaries directory to PATH if it exists
# 
if [ -d "/usr/local/go/bin" ]; then
    export PATH="$PATH:/usr/local/go/bin"
fi
