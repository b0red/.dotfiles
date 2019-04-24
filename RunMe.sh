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
##          Dependencies: Git installed
##
##          Requirements (These will be installed automatically):
##          zip, htop, tree, ncdu, pydf, 
##          The following needs to be installed manually, if you want them,
##          bat (optional), prettyping (optional)
##
##          v2.7
##
##          ref:
##          https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script
##          https://stackoverflow.com/questions/3557037/appending-a-line-to-a-file-only-if-it-does-not-already-exist
##          https://cromwell-intl.com/open-source/package-management.html
##          https://www.oracle.com/technetwork/articles/servers-storage-admin/o11-083-ips-basics-523756.html
##          https://git-scm.com/book/en/v2/Git-Tools-Submodules
##          
##          https://github.com/sharkdp/bat/releases/download/v0.10.0/bat_0.10.0_amd64.deb; sudo dpkg -i bat_0.10.0_amd64.deb; rm -f bat*
##          curl -O https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping; chmod +x prettyping; mv prettyping ~/bin
##
################################################################################################################################
clear

#
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
#

###     Debug on/off  - Change for debugging purposes
#
debug=1
trace_debug=1
SLEEP=0

###     Settings - Change if you need to
#
DIR=~/dotfiles/oldfiles                             # Where to store old backuped files
OLDFILES=oldfiles.txt                               # Filelist - not in use right now
FILE="$HOSTNAME-`date +%Y-%m-%d-%H:%M`.zip"         # Filename
ARCHIVE="$FILE"                                     # Arhchive name
LOG=~/dotfiles/install_progress_log                 # Installation prograss log
DATE=$(date +"%Y-%m-%d %H:%M:%S")                   # Date - for zipfile
TITLE="Dotfiles Installer Script"                   # scriptname

###     Software array
#
APPARRAY=(curl htop ncdu pydf tree tmux vim mc)     # Apps to be installed - add if you like
DOTARRAY=(.profile .bashrc)                         # old dotfiles
OLDFILEARRAY=(.bashrc .profile .bash_profile .inputrc)
#SUBMODULES=(https://github.com/denilsonsa/prettyping.git https://github.com/tlatsas/bash-spinner.git) #s submodules for git repos

###     LogMessages
#
LOG_MESS_01="Ran function date_it"
LOG_MESS_01_1="Quering for OS and other info!"
LOG_MESS_02="Setting specific aliases for this system.\n" 
LOG_MESS_03="Created backup dir"
LOG_MESS_04="Ran function 'app_installer'"
LOG_MESS_05="Moved old files to ${DIR} and symlinked the new ones!"
LOG_MESS_06="Ran function 'archive_it'"
LOG_MESS_07="Cloning TMUX and submodules"
LOG_MESS_07_1="Cloning additional TMUX stuff"
LOG_MESS_07_1_a="Not updating submodules"
LOG_MESS_07_1_b="Submodules updated!"
LOG_MESS_07_2="gvimrc doesn't exist"
LOG_MESS_07_3="Added line for .tmux-git to .bashrc"
LOG_MESS_08="Cloning VÍM and submodules"

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
###     ^NO Editing below this line ^
###    Tracedebug
#
if [ $trace_debug -eq 1 ]; then
    set -x
    trap read debug
fi

unalias -a

###     Check for logfile else create it
#
function date_it(){
    rm -f ${LOG}
    touch ${LOG}
    #[[ $debug -eq 1 ]] && echo -e "\n$TITLE - $DATE\n"; sleep ${SLEEP}
    [[ $debug -eq 1 ]] && echo -e "\n$TITLE - $DATE\n" || echo -e "\n$TITLE - $DATE\n" > ${LOG}; sleep ${SLEEP}
}

###     Function for updating submodules
#
function submodules_init(){
    git submodule init && git submodule update
}

function submodules_update(){
    git submodule foreach git pull origin master
}

function app_installer(){
    ###     Installs software
    #
    for APP in "${APPARRAY[@]}"
    do
        #echo $APP
        if command -v $APP 2> /dev/null; then
            [[ $debug -eq 1 ]] && echo "${APP} already installed" || echo -e "$APP already installed!" >> $LOG; sleep ${SLEEP}
        elif ! [ -x command -v $APP 2>/dev/null ]; then
           sudo apt install $APP
            [[ $debug -eq 1 ]] && echo "installing ${APP}" || echo -e "Installed $APP" >> $LOG; sleep ${SLEEP}
        else
            [[ $debug -eq 1 ]] && echo "${APP} failed to install!" || echo "$APP FAILED TO INSTALL!!!" >> $LOG; sleep ${SLEEP}
        fi
    done 
}

function copy_old_files() {
    # copies old dotfiles to backup folder
    for OLDFILE in "${OLDFILEARRAY[@]}"
        do
            cp ~/$OLDFILE $DIR/ 2>/dev/null
            [[ $debug -eq 1 ]] && echo "$OLDFILE moved to $DIR" || echo "$OLDFILE moved to $DIR" >> $LOG ; sleep ${SLEEP}
        done
}

function archive_it() {
     ### Archive the old files if there are any
     #
     if [ -n "$(find ${DIR} -prune -empty 2>/dev/null)" ]; then
        FILE_STATUS="File or directory empty. Nothing to archive!"
    else
        zip -r -q -u -m $DIR/$FILE $DIR -x "*.zip" && FILE_STATUS="Files compressed ok!" || FILE_STATUS="Files not compressed!"
    fi
    [[ $debug -eq 1 ]] && echo $FILE_STATUS || echo $FILE_STATUS >> $LOG ; sleep ${SLEEP}
}

function sym_link_check(){
    ###     Check for old (sym)links
    for LINK in "${DOTARRAY[@]}"
    do
    ###     Test if files are symlimked or not
        if [ -L ${LINK} ] ; then
           if [ -e ${LINK} ] ; then
                ### Found link
                LINK_STATUS="removing $LINK" 
                [[ $debug -eq 1 ]] && echo $LINK_STATUS || echo $LINK_STATUS >> $LOG; sleep ${SLEEP}
                rm -f $LINK 
            else
                ### Broken link
                LINK_STATUS="Broken link: $LINK, removing it!"
                [[ $debug -eq 1 ]] && echo $LINK_STATUS || echo $LINK_STATUS >> $LOG ; sleep ${SLEEP}
                rm -f $LINK
             fi
        elif [ -e ${LINK} ] ; then
            ### Broken link
            LINK_STATUS="$LINK is not a symlink. Moving it" 
            [[ $debug -eq 1 ]] && echo $LINK_STATUS || echo $LINK_STATUS >> $LOG ; sleep ${SLEEP}
            mv $LINK $DIR
        else
            ### Missing link
            LINK_STATUS="Missing: $LINK. Symlinking it!"
            [[ $debug -eq 1 ]] && echo $LINK_STATUS || echo $LINK_STATUS >> $LOG ; sleep ${SLEEP}
            ln -s ~/dotfiles/$LINK ~/
            #[[ $debug -eq 1 ]] && echo "updating submodules" || echo "updating submodules"; sleep ${SLEEP}
        fi
    done
}

function get_os(){
    #checks for os tyoe, this to alias right things
    OS=$(uname); OS="${OS,,}"
    KERNEL=$(uname -r)
    MACH=$(uname -m)
    if [ "${OS}" == "windowsnt" ]; then
        OS=windows; OSSYS="windows"
    elif [ "${OS}" == "darwin" ]; then
        OS=mac; OSSYS="mac"
    else
        OS="linux"
        if [ "${OS}" = "SunOS" ] ; then
            OS=Solaris; OSSYS="solaris"
            ARCH=$(uname -p)
            OSSTR="${OS} ${REV}(${ARCH} "uname -v")"
        elif [ "${OS}" = "AIX" ] ; then
            OSSTR="${OS} "oslevel" ("oslevel -r")"
        elif [ "${OS}" = "linux" ] ; then
            if [ -f /etc/redhat-release ] ; then
                DistroBasedOn='RedHat'; OSSYS="redhat"
                DIST=$(cat /etc/redhat-release |sed s/\ release.*//)
                PSEUDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
                REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
            elif [ -f /etc/SuSE-release ] ; then
                DistroBasedOn='SuSe'; OSSYS="suse"
                PSEUDONAME=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
                REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
            elif [ -f /etc/mandrake-release ] ; then
                DistroBasedOn='Mandrake'; OSSYS="mandrake"
                PSEUDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
                REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
            elif [ -f /etc/debian_version ] ; then
                DistroBasedOn='Debian'; OSSYS="debian"
                DIST=$(cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
                PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
                REV=$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')
            fi
            if [ -f /etc/UnitedLinux-release ] ; then
                DIST=$(${DIST}["cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//"])
                OSSYS="unitedlinux"
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
            readonly OSSYS
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
    case $OSSYS in
        solaris*) 
            [[ $debug -eq 1 ]] && echo "OS är: SOLARIS"; sleep ${SLEEP}
            alias install="pkg install" $1
            alias uninstall="pkg uninstall" $1
            alias app_search="pkg search" $1
            alias update="pkg update --accept" 
            ;;
        darwin*)  
            [[ $debug -eq 1 ]] && echo "OS är: OSX"; sleep ${SLEEP}
            ;; 
        debian*)   
            [[ $debug -eq 1 ]] && echo "OS är: LINUX (Debian)"; sleep ${SLEEP}
            alias rm='rm -i' 
            alias apt_update="sudo aptitude update"
            alias {sys_update,sysup,sysupdate}="sudo apt-get update && sudo apt-get upgrade"
            alias install="apt-get install" $1
            alias uninstall="sudo apt remove"
            alias sysclean="sudp apt clean; sudo apt autoremove; sudo apt purge"
            ;;
        bsd*) 
            [[ $debug -eq 1 ]] && echo "OS är: *BSD"; sleep ${SLEEP}
            alias install="pkg install" $1
            alias uninstall="pkg delete" $1
            alias {sys_update,sysup,sysupdate}="freebsd-update fetch && freebsd-update install"
            alias upgrade="pkg update && pkg upgrade"
            alias autoclean="pkg autoremove"
            alias clean="pkg clean -c"
            ;;
        redhat*)                                                            #     YUM (RedHat Linux, centos)
            [[ $debug -eq 1 ]] && echo "OS är: RedHat"; sleep ${SLEEP}
            #PATH=$PATH:$HOME/bin
            alias install="sudo yum install -y" $1
            alias {uninstall,remove}="sudo yum remove" $1
            alias update="sudo yum update -y"
            alias upgrade="sudo yum upgrade -y"
            alias swap="sudo yum swap" $1 $2
            alias autoremove="sudo yum autoremove" $1
            alias reinstall="sudo yum reinstall" $1
            ;;
        suse*)                                                            #     OpenSuSe)
            [[ $debug -eq 1 ]] && echo "OS är: OpenSUSE"; sleep ${SLEEP}
            alias install="zypper install" $1
            alias uninstall="zypper remove" $1
            alias app_search="zypper search" $1
            alias update="sudo zypper refresh; sudo zypper dup"
            alias sysclean="sudo zypper clean -a"
            alias dist_upgrade="sudo zypper dist-upgrade"
            ;;
        fedora*)                                                           #        Fedora
            [[ $debug -eq 1 ]] && echo "OS är: Fedora"; sleep ${SLEEP}
            alias install="dnf install" $1
            alias {uninstall,remove}l="dnf remove" $1
            alias upgrade="dnf upgrade"
            alias search="dnf search" $1
            alias autoremove="dnf remove" $1
            alias sysclean="dnf clean all"
            ;;
        pacman*)                                                           #        ArchLinux
            [[ $debug -eq 1 ]] && echo "OS är: PacMan"; sleep ${SLEEP}
            alias install="pacman -Syu" $1
            alias {uninstall,remove}="pacman -Rsc" $1
            alias force_install="pacman -S --force" $1
            alias reinstall="pacman -Syu $(pacman -Qqen)"
            alias update="pacman -Syu"
            alias sysclean="pacman -Sc"
            alias package_list="pacman -Q"
            ;;
        msys*)    
            [[ $debug -eq 1 ]] && echo "OS är: WINDOWS" ; sleep ${SLEEP}
            ;;
        *)        
            [[ $debug -eq 1 ]] && echo "OS är: unknown: $OSTYPE"; sleep ${SLEEP} 
            ;;
    esac
}





# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     On first run. This is a quick and dirty script, no backups or questions asked!

date_it
[[ $debug -eq 1 ]] && echo "$LOG_MESS_01" || echo "${LOG_MESS_01}" >> $LOG; sleep ${SLEEP}

###     Run get_os and set same aliases for different os' commands
#
get_os
[[ $debug -eq 1 ]] && echo -e "$LOG_MESS_01_1" || echo -e $LOG_MESS_01_1 >> $LOG; sleep ${SLEEP}
[[ $debug -eq 1 ]] && echo -e "OS=$OS\nDIST=$DIST\nDistroBasedOn=$DistroBasedOn" || echo -e \
OS=$OS\nDIST=$DIST\nDistroBasedOn=$DistroBasedOn >> $LOG; sleep ${SLEEP}

setting_standard_commands
[[ $debug -eq 1 ]] && echo -e "$LOG_MESS_02" || echo -e "${LOG_MESS_02}" >> $LOG;  sleep ${SLEEP}
[[ $debug -eq 1 ]] && echo "Added aliases for $OSSYS!"; sleep ${SLEEP}

###     Feth any updates to the dotfiles
#
git pull origin master

###     If debug mode is on (=1) then don't fetch submodules, faster
#
[[ $debug -eq 1 ]] && echo "Not fetching submodules" || submodules_init; echo "Submodules added!" >> $LOG
#[[ $debug -eq 1 ]] && echo "ran submodules_init" ; sleep ${SLEEP}
[[ $debug -eq 1 ]] && echo "Not updating submodules" || submodules_update; echo "Submodules updated!" >> $LOG

###     Create backup dir
#
mkdir $DIR 2> /dev/null
[[ $debug -eq 1 ]] && echo "$LOG_MESS_03" || echo "$LOG_MESS_03 $DIR" >> $LOG ; sleep ${SLEEP}
echo $LOG_MESS_03 >> $LOG

###     install various apps from array
#
app_installer
[[ $debug -eq 1 ]] && echo "$LOG_MESS_04" || echo "$LOG_MESS_04" >> $LOG; sleep ${SLEEP}

###     Moving/Copying old files
# mv ~/.profile $DIR/; mv ~/.bashrc $DIR/; 
copy_old_files
ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile
[[ $debug -eq 1 ]] && echo "$LOG_MESS_05" || echo "$LOG_MESS_05" >> $LOG; sleep ${SLEEP}

archive_it
[[ $debug -eq 1 ]] && echo "$LOG_MESS_06" || echo "$LOG_MESS_06" >> $LOG; sleep ${SLEEP}

###     Clone tmux repo
#
git clone --recurse-submodules git@bitbucket.org:b0red/tmux.git ~/.tmux; cd ~/.tmux
[[ $debug -eq 1 ]] && echo "Not updating submodules! (TMUX)" || submodules_update; echo "Submodules updated! (TMUX)" >> $LOG
ln -s ~/.tmux/.tmux.conf ~/.tmux.conf
[[ $debug -eq 1 ]] && echo "$LOG_MESS_07" || echo "$LOG_MESS_07" >> $LOG; sleep ${SLEEP}

###     Clone additional tmux stuff
#
#git clone git://github.com/drmad/tmux-git.git ~/.tmux-git
#git clone git://github.com/arl/tmux-gitbar ~/.tmux-gitbar
ln -s extras/tmux-git.git ~/.tmux-git
ln -s extras/tmux-gitbar ~/.tmux-gitbar
[[ $debug -eq 1 ]] && echo "$LOG_MESS_07_1" || echo "$LOG_MESS_07_1" >> $LOG; sleep ${SLEEP}


###     Check if line exists in file .bashrc, if not copy it
#
grep -qxF "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" ~/.bashrc
if [ $? -ne 0 ]; then
    echo "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" >> ~/.bashrc
    [[ $debug -eq 1 ]] && echo "$LOG_MESS_07_3" || echo "$LOG_MESS_07_3" >> $LOG; sleep ${SLEEP}
else
    status="Line not added!";  echo $status
fi

###     Clone vim repo & submodules & symlink files
#
git clone --recurse-submodules git@bitbucket.org:b0red/.vim.git ~/.vim; cd ~/.vim
[[ $debug -eq 1 ]] && echo "$LOG_MESS_07_1_a" || submodules_update; echo "$LOG_MESS_07_1_b" >> $LOG
ln -s ~/.vim/vimrc ~/vimrc; 
[[ -f ~/.vim/gvimrc ]] && ln -s ~/.vim/gvimrc ~/gvimrc; echo "Symlinked gvimrc" || echo "$LOG_MESS_07_2"; \
echo "$LOG_MESS_07_2" >> $LOG
[[ $debug -eq 1 ]] && echo "$LOG_MESS_08" || echo "$LOG_MESS_08" >> $LOG; sleep ${SLEEP}

 
###     Source .bashrc
#
source  ~/.bashrc
# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     Show summary of what was done
#
sleep 5
#clear; 
echo -e "\n====== Summary ======\nResult of $TITLE"
cat $LOG
sleep ${SLEEP}
[[ ! $debug -eq 1 ]] && exit 0
    
## ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
###     Debuginfo - just printing  values to screen
#
if [ $debug -eq 1 ]; then
    clear
    echo -e "\n$TITLE"
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
