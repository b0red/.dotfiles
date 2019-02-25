#!/bin/bash -p
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export TERM=${TERM:-dumb}
export DISPLAY=:0.0

_DIR=~/dotfiles/oldfiles
APPARRAY=(curl htop ncdu pydf tree tmux vim)
DOTARRAY=(.profile .bashrc .junk)

function command_exists() {
        command -v "$1" >/dev/null 2>&1
}

###		Check if folder exists
#
function app_installer(){
    ###     Install software (yes/no)
    #
    for APP in "${APPARRAY[@]}"
    do
        # echo $APP
        #install $APP
        if command_exists $APP; then
            echo "$APP already installed!" #>> $LOG
        elif  ! command_exists $APP; then
            echo installing $APP #install $APP
        else
            echo "$APP FAILED TO INSTALL!!!" #>> $LOG
        fi
    done 
}

#	echo Checking links
function sym_link_check(){
	for LINK in "${DOTARRAY[@]}"
	do
	###		Test if files are symlimked
		if [ -L ~/${LINK} ] ; then
		   if [ -e ~/${LINK} ] ; then
		      echo "Good link: $LINK"
		      echo removing link
		      rm -f $LINK
		   else
		      echo "Broken link: $LINK"
		      echo removing link
		      rm -f $LINK
		   fi
		elif [ -e ~/${LINK} ] ; then
		   echo "Not a link: $LINK"
		   echo moving link
		   mv $LINK $DIR
		else
		   # Doing nothing
			echo "Missing: $LINK"
		   fi
	done
}

echo checking .links
sym_link_check
exit 0