# ---------------------------------------------------------------------------
# 
#	.bash_profile
#
# ---------------------------------------------------------------------------

###	Now if bash is started as an interactive login shell it will read the following files:
#
# 1 ~/.bash_profile
# 2 ~/.profile
# 3 ~/.bashrc
# and if bash is started as an interactive non-login shell:
# ~/.bashrc

[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"

###	Source the .files
if [ -f ~/dotfiles/.bash_aliases ]; then
    source ~/dotfiles/.bash_aliases
fi
if [ -f ~/dotfiles/.bash_functions ]; then
    source ~/dotfiles/.bash_functions
fi
if [ -f ~/dotfiles/.bash_env ]; then
    source ~/dotfiles/.bash_env
fi
if [ -f ~/dotfiles/.bash_export ]; then
    source ~/dotfiles/.bash_export
fi
if [ -f ~/dotfiles/.bash_git ]; then
    source ~/dotfiles/.bash_git
fi
if [ -f ~/dotfiles/.bash_profile ]; then
    source ~/dotfiles/.bash_git
fi
#if [ -f ~/dotfiles/.bash_profile ]; then
#    source ~/dotfiles/.bash_profile
#fi
 

