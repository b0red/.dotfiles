#!/bin/bash -p
###############################################################################################
##
##
##          This is just for testing
##          https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script
##
###############################################################################################

debug=0


grep -qxF "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" ~/.bashrc
if [ $? -ne 0 ]; then
  #sed -i "$ a port=9033" $light.conf
  echo line is there
else
    echo "port=9033 already added"
fi