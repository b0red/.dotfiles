###     WSL-Specific: Proper Loading Order (add to ~/.bash_profile if exists, or create):
#

# ~/.bash_profile: Load .bashrc for non-login shells
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi