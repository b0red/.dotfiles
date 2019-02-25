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
##          Requirements (Theese will be installed ):
##          zip, htop, tree, ncdu, pydf, bat (optional), prettyping (optional)
##
################################################################################################
clear

#
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#

###     Settings
DIR=~/dotfiles/oldfiles                         # Where to store old backuped files
OLDFILES=oldfiles.txt                           # Filelist
FILE="$HOSTNAME-`date +%Y-%m-%d-%H:%M`.zip"     # Filename
ARCHIVE="$FILE"                                 #
LOG=install_progress_log                        # Installation prograss log
DATE=$(date +"%Y-%m-%d %H:%M:%S")                  # Date
NAME="Dotfiles installer"                       #

###     Software array
#
APPARRAY=(curl htop ncdu pydf tree tmux vim)
DOTARRAY=(.profile .bashrc)
SUBMODULES=(https://github.com/denilsonsa/prettyping.git)


### 	Debug on/off
#
debug=1
trace_debug=1

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

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
    echo -e "\n\n$NAME - $DATE" > ${LOG}
}

###     Function for updating submodules
#
function modules_init(){
    git submodule init && git submodule update
}

function modules_update(){
    git submodule foreach git pull origin master
}

function app_installer(){
    ###     Install software (yes/no)
    #
    for APP in "${APPARRAY[@]}"
    do
        echo $APP
        #install $APP
        if command -v 2> /dev/null; then
            echo "$APP already installed!" >> $LOG
        elif -x command -v  2>/dev/null ; then
            echo installing $APP #install $APP
        else
            echo "$APP FAILED TO INSTALL!!!" >> $LOG
        fi
    done 
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
            status="linking: ~/dotfiles/$LINK ~/"
            [[ $debug -eq 1 ]] && echo $LINK_STATUS; sleep 1
            ln -s ~/dotfiles/$LINK ~/
            modules_update
            [[ $debug -eq 1 ]] && echo updating submodules; sleep 1
            #ln -s ~/dotfiles/.bashrc ~/.bashrc
           #ln -s ~/dotfiles/.profile ~/.profile
        fi
    done
}

###     On first run, check if folder alreay exists. If so, aks if update or create dotfiles
#
if [ ! -d $DIR ]; then
    ###     Directory doesnt exist, do stuff here
    ###     Run logfile checker
    #
    date_it
    [[ $debug -eq 1 ]] && echo running date_it; sleep 1
    mkdir $DIR
    status="Couldn't find $DIR. Creating it!"
    [[ $debug -eq 1 ]] && echo $status; sleep 1
    ###     Install apps
    #
    app_installer
    [[ $debug -eq 1 ]] && echo running app_installer; sleep 1
    modules_update
    [[ $debug -eq 1 ]] && echo running modules_update; sleep 1
else
    status="Found $DIR!"
    #echo $DIR
    if ([ $(ls $DIR | wc -l  | grep -w "0") ])
    then
        ###     Directory empty, create files
        status='No files'
        sym_link_check 
        [[ $debug -eq 1 ]] && echo running sym_link_check; sleep 1
    else
        ###     Direcrory not empty (might be other files)
        status="~/dotfiles found!"; echo $status; sleep 1 #echo 'Found files';
        
        ### Archive the files if there are any
        #
        if [ ! -n "$(find "$DIR" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
            #echo HOST: $HOSTNAME
            zip -r -q -u -m $DIR/$FILE -x "*.zip" && FILE_STATUS="Files compressed ok!" || FILE_STATUS="Files not compressed!"
            # echo $FILE_STATUS
        else
            FILE_STATUS="Empty directory, nothing to archive!"
            # echo $FILE_STATUS
        fi
        echo $FILE_STATUS >> $LOG
        #echo $FILE_STATUS
        sleep 2
    fi
fi

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

###     Show summary of what was done
#
echo -e "\n====== Summary ======\n"
cat $LOG
sleep 5

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
###     Debuginfo
#
clear
if [ $debug -eq 1 ]; then
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
    echo -e "Name:              $NAME"
    echo -e ""
    echo -e "Summary:\ncat < $LOG"
fi

### Send it by pushover
#

exit 0
