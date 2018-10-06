#!/bin/bash -p
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export TERM=${TERM:-dumb}
export DISPLAY=:0.0

################################################################################################
##
##      Script for installing dotfiles. It will copy and backup old dotfiles to location under 
##          ~/dotfiles/oldfiles/$HOSTNAME
##          
##          Dependencies: Not really
##
##          Requirements: zip, htop, tree, ncdu, pydf, bat (optional), prettyping (optional)
##
################################################################################################
clear

#
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#

###     Settings
BACKUPDIR=~/dotfiles/oldfiles
OLDFILES=oldfiles.txt
FILE="$HOSTNAME-`date +%Y-%m-%d-%H:%M`.zip"
ARCHIVE="$FILE"

### 	Debug on/off
#
debug=1
trace_debug=0

###     Notifications
#
mailit=0
pushit=0

###     Variables/constants
#
#SCRIPT=$(readlink -f "$0")
#SCRIPTPATH=$(dirname "$SCRIPT")

###     Include / Source files
#source $SCRIPTPATH/email_variables.inc
#source $SCRIPTPATH/ColorCodes.inc
#source $SCRIPTPATH


#
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#
###    Tracedebug
#
if [ $trace_debug -eq 1 ]; then
    set -x
    trap read debug
fi


###     Create backupdir
#
if [[ ! -d "$BACKUPDIR/$HOSTNAME" ]]; then 
    mkdir $BACKUPDIR/$HOSTNAME
    DIRSTATUS="$BACKUPDIR/$HOSTNAME created!"
else
    DIRSTATUs="$BACKUPDIR/$HOSTNAME already exists!"
fi

### Move old .dotfiles to backupfolder and archive them
#   skip symlinked files
#
cat $OLDFILES | while read FILE ; 
do 
    # Symlink check
    # [[ -L $HOME/$FILE ]] && echo symlink || echo not symlink
    if [[ ! -f $HOME/$FILE ]]; then
        echo "$FILE does not exist"
        # MVSTATUS="$FILE copied to $BACKUPDIR/$HOSTNAME"
    else
        [[ -L $HOME/$FILE ]] && echo "$FILE is a symlink, not moved!" || cp $FILE $BACKUPDIR/$HOSTNAME;
    fi
done

### Archive the files if there are any
#
if [ ! -n "$(find "$BACKUPDIR/$HOSTNAME" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
    zip -r -q -u -m $BACKUPDIR/$HOSTNAME/$ARCHIVE $BACKUPDIR/$HOSTNAME && FILE_STATUS="Files compressed ok!" || FILE_STATUS="Files not compressed!"
    # echo $FILE_STATUS
else
    FILE_STATUS="Empty directory, nothing to archive!"
    # echo $FILE_STATUS
fi

### Symlink the new files
#
ln -s ~/dotfiles/.bashrc ~/.bashrc
ln -s ~/dotfiles/.profile ~/.profile

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
###     Debuginfo
#
clear
if [ $debug -eq 1 ]; then
    echo -e "Output from:${ORANGE} ${0##*/} ${NC} \n"
    echo -e "Hostname:      $HOSTNAME\n"
    echo -e "Backupdir:     $BACKUPDIR"
    echo -e "Folderpath:    $BACKUPDIR/$HOSTNAME\n"
    echo -e "Filestatus:    $FILE_STATUS"
    echo -e "Filename:      $ARCHIVE"
    echo -e "zipstring: "
fi

### Send it by pushover
#

exit 0
