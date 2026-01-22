### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-22 03:58:00
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

###     WSL-Specific: Proper Loading Order (add to ~/.bash_profile if exists, or create):
#

# ~/.bash_profile: Load .bashrc for non-login shells
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
source /home/patrick/.config/broot/launcher/bash/br
