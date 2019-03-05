#!/bin/bash -p
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export TERM=${TERM:-dumb}
export DISPLAY=:0.0
################################################################################################################################
##
##                   W A R N I N G !  - You ar running this at your own risk½
##
##
##      Script for installing dotfiles. It will copy and backup old dotfiles to location under 
##          ~/dotfiles/oldfiles/$HOSTNAME
##          
##          Dependencies: Not really
##
##          Requirements (Theese will be installed ):
##          zip, htop, tree, ncdu, pydf, bat (optional), prettyping (optional)
##
##          v2.5
##
##          ref:
##          https://stackoverflow.com/questions/3557037/appending-a-line-to-a-file-only-if-it-does-not-already-exist
##
################################################################################################################################
clear

#
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
#

###     Settings - Change if you need to
DIR=~/dotfiles/oldfiles                             # Where to store old backuped files
OLDFILES=oldfiles.txt                               # Filelist - not in use right now
FILE="$HOSTNAME-`date +%Y-%m-%d-%H:%M`.zip"         # Filename
ARCHIVE="$FILE"                                     # Arhchive name
LOG=install_progress_log                            # Installation prograss log
DATE=$(date +"%Y-%m-%d %H:%M:%S")                   # Date - for zipfile
SOURCE="Dotfiles installer Script"                  # scriptname

###     Software array
#
APPARRAY=(curl htop ncdu pydf tree tmux vim mc)     # Apps to be installed - add if you like
DOTARRAY=(.profile .bashrc)                         # old dotfiles
#SUBMODULES=(https://github.com/denilsonsa/prettyping.git https://github.com/tlatsas/bash-spinner.git)   #s submodules for git repos

### 	Debug on/off
#
debug=0
trace_debug=0

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###    Tracedebug
#
if [ $trace_debug -eq 1 ]; then
    set -x
    trap read debug
fi

###     Check for logfile else create it
#
function date_it(){
    #[[ -e $LOG ]] && rm -f $LOG || touch $LOG; echo -e "\n\n$NAME - $DATE" > $LOG
    #[[ -e ${LOG} ]] && rm -f ${LOG} || (touch ${LOG}; echo -e "\n\n$NAME - $DATE" > ${LOG})
    rm -f ${LOG}
    touch ${LOG} 
    echo -e "\n$SOURCE - $DATE" > ${LOG}
}

###     Function for updating submodules
#
function submodules_init(){
    git submodule init #&& git submodule update
}

function submodules_update(){
    git submodule foreach git pull origin master
}

function app_installer(){
    ###     Install software (yes/no)
    #
    for APP in "${APPARRAY[@]}"
    do
        #echo $APP
        if command -v $APP 2> /dev/null; then
            echo "$APP already installed!" >> $LOG
            [[ $debug -eq 1 ]] && echo "${APP} already installed"; sleep 1
        elif ! [ -x command -v $APP 2>/dev/null ]; then
           sudo apt install $APP
            echo "Installed $APP" >> $LOG
            [[ $debug -eq 1 ]] && echo "installing ${APP}"; sleep 1
        else
            echo "$APP FAILED TO INSTALL!!!" >> $LOG
            [[ $debug -eq 1 ]] && echo "${APP} failed to install!"; sleep 1
        fi
    done 
}

function archive_it() {
     ### Archive the files if there are any
     #
     if [ -n "$(find ${DIR} -prune -empty 2>/dev/null)" ]; then
        FILE_STATUS="File or directory empty. Nothing to archive!"
    else
        zip -r -q -u -m $DIR/$FILE $DIR -x "*.zip" && FILE_STATUS="Files compressed ok!" || FILE_STATUS="Files not compressed!"
    fi
    [[ $debug -eq 1 ]] && echo $FILE_STATUS ; sleep 1
    echo $FILE_STATUS >> $LOG
}

###     Check for old (sym)links
#
function sym_link_check(){
    for LINK in "${DOTARRAY[@]}"
    do
    ###     Test if files are symlimked
        if [ -L ${LINK} ] ; then
           if [ -e ${LINK} ] ; then
                ### Found link
                LINK_STATUS="removing $LINK" 
                echo $LINK_STATUS >> $LOG
                [[ $debug -eq 1 ]] && echo $LINK_STATUS ; sleep 1
                rm -f $LINK 
            else
                ### Broken link
                echo "Broken link: $LINK"
                LINK_STATUS="Broken link: $LINK, removing it!"
                echo $LINK_STATUS >> $LOG 
                [[ $debug -eq 1 ]] && echo $LINK_STATUS ; sleep 1
                rm -f $LINK
             fi
        elif [ -e ${LINK} ] ; then
            ### Broken link
            #echo "Not a link: $LINK"
            LINK_STATUS="$LINK is not a symlink. Moving it" 
            echo $LINK_STATUS >> $LOG 
            [[ $debug -eq 1 ]] && echo $LINK_STATUS ; sleep 1
            mv $LINK $DIR
        else
            ### Missing link
            LINK_STATUS="Missing: $LINK. Symlinking it!"
            [[ $debug -eq 1 ]] && echo $LINK_STATUS; sleep 1
            ln -s ~/dotfiles/$LINK ~/
            [[ $debug -eq 1 ]] && echo updating submodules; sleep 1
        fi
    done
}

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     On first run. This is a quick and dirty script, no backups or questions asked!

###     Feth any updates to the dotfiles
#
git pull origin master
#
date_it
[[ $debug -eq 1 ]] && echo "ran date_it" ; sleep 1  

mkdir $DIR 2> /dev/null; echo "Created folder: $DIR" >> $LOG
[[ $debug -eq 1 ]] && echo "ran mkdir" ; sleep 1

app_installer
[[ $debug -eq 1 ]] && echo "ran app_installer" ; sleep 1

mv ~/.profile $DIR/; mv ~/.bashrc $DIR/; 
ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile
echo "Moved old files to ${DIR} and symlinked the new ones!" >> $LOG
[[ $debug -eq 1 ]] && echo "ran symlink" ; sleep 1

archive_it
[[ $debug -eq 1 ]] && echo "ran archive_it" ; sleep 1

###     If debug mode is on (=1) then dont fetch submodules, faster
#
[[ $debug -eq 1 ]] && echo "Not fetching submodules" || submodules_init; echo "submodules added!" >> $LOG
[[ $debug -eq 1 ]] && echo "ran submodules_init" ; sleep 1

[[ $debug -eq 1 ]] && echo "Not updating submodules" || submodules_update; echo "Submodules updated!" >> $LOG
[[ $debug -eq 1 ]] && echo "ran submodules_update" ; sleep 1

###     Clone tmux repo
#
git clone git@bitbucket.org:b0red/tmux.git ~/.tmux
cd ~/.tmux; 
submodules_update
ln -s ~/.tmux/.tmux.conf ~/.tmux.conf

git clone git://github.com/drmad/tmux-git.git ~/.tmux-git

###     Check if line exists is file
#
grep -qxF "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" ~/.bashrc
if [ $? -ne 0 ]; then
    echo "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" >> ~/.bashrc
    echo "Line added to .tmux-git to .bashrc" >> $LOG
else
    status="Line not added!"
fi

###     Clone vim repo
#
git clone git@bitbucket.org:b0red/.vim.git ~/.vim
cd ~/.vim; 
submodules_update
ln -s ~/.vim/vimrc ~/vimrc; ln -s ~/.vim/gvimrc ~/gvimrc

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     Show summary of what was done
#
clear; echo -e "\n====== Summary ======\nResult of $SOURCE"
cat $LOG
sleep 10
[[ ! $debug -eq 1 ]] && exit 0
    
## ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
###     Debuginfo - just printing  values to screen
#
if [ $debug -eq 1 ]; then
    clear
    echo -e "\n$SOURCE"
    echo -e "\nOutput from:${ORANGE} ${0##*/} ${NC} \n"
    echo -e "Hostname:          $HOSTNAME\n"
    echo -e "BackupDIR:         $DIR"
    echo -e "Oldfiles:          $OLDFILES"
    echo -e "File:              $FILE"
    echo -e "Folderpath:        $DIR/$HOSTNAME\n"
    echo -e "Archive status:    $FILE_STATUS"
    echo -e "Archive name:      $ARCHIVE"
    echo -e "Logfile:           $LOG"
    echo -e "Date:              $DATE"
fi
exit 0
