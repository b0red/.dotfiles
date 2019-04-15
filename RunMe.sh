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
##          Requirements (These will be installed ):
##          zip, htop, tree, ncdu, pydf, bat (optional), prettyping (optional)
##
##          v2.6
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
LOG=~/dotfiles/install_progress_log                 # Installation prograss log
DATE=$(date +"%Y-%m-%d %H:%M:%S")                   # Date - for zipfile
SOURCE="Dotfiles installer Script"                  # scriptname

###     Software array
#
APPARRAY=(curl htop ncdu pydf tree tmux vim mc)     # Apps to be installed - add if you like
DOTARRAY=(.profile .bashrc)                         # old dotfiles
#SUBMODULES=(https://github.com/denilsonsa/prettyping.git https://github.com/tlatsas/bash-spinner.git) #s submodules for git repos

### 	Debug on/off
#
debug=1
trace_debug=1

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

function get_os(){
OS=$(uname); OS="${OS,,}"
KERNEL=$(uname -r)
MACH=$(uname -m)

if [ "${OS}" == "windowsnt" ]; then
    OS=windows
elif [ "${OS}" == "darwin" ]; then
    OS=mac
else
    OS="linux"
    if [ "${OS}" = "SunOS" ] ; then
        OS=Solaris
        ARCH=$(uname -p)
        OSSTR="${OS} ${REV}(${ARCH} "uname -v")"
    elif [ "${OS}" = "AIX" ] ; then
        OSSTR="${OS} "oslevel" ("oslevel -r")"
    elif [ "${OS}" = "linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='RedHat'
            DIST=$(cat /etc/redhat-release |sed s/\ release.*//)
            PSEUDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='SuSe'
            PSEUDONAME=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
            REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='Mandrake'
            PSEUDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='Debian'
            DIST=$(cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
            PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
            REV=$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST=$(${DIST}["cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//"])
        fi
        OS="${OS,,}"
        DistroBasedOn="${DistroBasedOn,,}"
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSEUDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
        ###     export variables
        # export OS
        # export DIST
        # export DistroBasedOn
        # export PSEUDONAME
        # export REV
        # export KERNEL
        # export MACH
    fi
fi
}

function setting_standard_commands(){
###     YUM (RedHat Linux, centos)
#
if [[ -f /usr/bin/yum ]]
then
    [[ $debug -eq 1 ]] && echo YUM; sleep 1
    PATH=$PATH:$HOME/bin
    alias install="sudo yum install -y" $1
    alias uninstall="sudo yum remove" $1
    alias update="sudo yum update -y"
    alias upgrade="sudo yum upgrade -y"
    alias swap="sudo yum swap" $1 $2
    alias autoremove="sudo yum autoremove" $1
    alias reinstall="sudo yum reinstall" $1
fi
###     DNF Fedorah
#
if [[ -f /usr/bin/dnf ]]
then
    [[ $debug -eq 1 ]] && echo DNF; sleep 1
    alias upgrade="dnf upgrade"
    alias install="dnf install" $1
    alias uninstall="dnf remove" $1
    alias search="dnf search" $1
    alias autoremove="dnf remove" $1
    alias sysclean="dnf clean all"
fi
###     Pacman (ArchLinux)
#
if [[ -f /usr/bin/pacman ]]
then
    [[ $debug -eq 1 ]] && echo PacMan; sleep 1
    alias update="pacman -Syu"
    alias install="pacman -Syu" $1
    alias force_install="pacman -S --force" $1
    alias {uninstall,remove}="pacman -Rsc" $1
    alias sysclean="pacman -Sc"
    alias reinstall="pacman -Syu $(pacman -Qqen)"
    alias package_list="pacman -Q"
fi
###     APT (apt get...)
#
if [[ -f /usr/bin/aptitude ]]
then
    [[ $debug -eq 1 ]] && echo Debian/Ubuntu; sleep 1
    alias apt_update="sudo aptitude update"
    alias {sys_update,sysup,sysupdate}="sudo apt-get update && sudo apt-get upgrade"
    alias install="apt-get install" $1
    alias uninstall="sudo apt remove"
    alias sysclean="sudp apt clean; sudo apt autoremove; sudo apt purge"
    alias search="apt search" $1
fi
###     Zypper (opensuse)
#
if [[ -f /usr/bin/zypper ]]
then
    [[ $debug -eq 1 ]] && echo OpenSUSE; sleep 1
    alias app_search="zypper search" $1
    alias install="zypper install" $1
    alias uninstall="zypper remove" $1
    alias update="sudo zypper refresh; sudo zypper dup"
    alias sysclean="sudo zypper clean -a"
    alias dist_upgrade="sudo zypper dist-upgrade"
    #    alias upgrade="sudo yum safe-upgrade"
    #    alias install="sudo yum install"
    #    alias uninstall="sudo yum remove"
fi
###     Freebsd)                                    <--------------------- This might not work
#
if [[ -f /usr/sbin/pkg ]]
then
    [[ $debug -eq 1 ]] && echo FreeBSD; sleep 1
    alias app_search="zypper search" $1
    alias app_info="zypper install" $1
    alias install="pkg install" $1
    alias uninstall="pkg delete" $1
    #alias update="sudo zypper refresh; sudo zypper dup"
    alias upgrade="pkg upgrade"
    alias autoclean="pkg autoremove"
    alias clean="pkg clean -c"
fi
}
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     On first run. This is a quick and dirty script, no backups or questions asked!

###     Run get_os and set standards
#
get_os
[[ $debug -eq 1 ]] && echo Getting OS; sleep 1
[[ $debug -eq 1 ]] && echo OS=$OS; echo DIST=$DIST; echo DistroBasedOn=$DistroBasedOn; sleep 1
setting_standard_commands
[[ $debug -eq 1 ]] && echo Settings standard aliases; sleep 1


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
git clone git://github.com/arl/tmux-gitbar ~/.tmux-gitbar

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
ln -s ~/.vim/vimrc ~/vimrc; 
###     If gvim is installed
 if command_check gvimrc; then ln -s ~/.vim/gvimrc ~/gvimrc; fi
    

###     Source .bashrc
#
source  ~/.bashrc    
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
