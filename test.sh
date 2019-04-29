#!/bin/bash -p
###############################################################################################
##
##
##          This is just for testing
##          https://askubuntu.com/questions/1705/how-can-i-create-a-select-menu-in-a-shell-script
##
###############################################################################################

###		Check for 'firstrun'
if [ -f ~/dotfiles/firstrun ]; then
	# File has ran before
	###		Check value
	read -r line < firstrun
	#echo $line
	if [ $line = 0 ]; then 
	 	####	Do first ttime stuff here
	 	echo "it's 0"

	 else
	 	###		Do update stuff here
	 	echo "It's 1"
	fi
	else
	# This is the first time, file doesn't exist
fi