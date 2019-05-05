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
debug=0
trace_debug=0
SLEEP=0

###     Settings - Change if you need to
#
DIR=~/dotfiles/oldfiles                             # Where to store old backuped files
OLDFILES=oldfiles.txt                               # Filelist - not in use right now
FILE="$HOSTNAME-(date +%Y-%m-%d-%H:%M).zip"         # Filename
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
LOG_MESS_01="Ran function date_it."
LOG_MESS_01_1="\nChecking for OS specifics:"
LOG_MESS_02="Setting appropriate aliases for this system." 
LOG_MESS_03="Created backup dir: "
LOG_MESS_04="Ran function 'app_installer'"
LOG_MESS_05="\nSymlinked the new dotfiles!"
LOG_MESS_06="\nRan function 'archive_it'"
LOG_MESS_07="\nCloning TMUX and submodules"
LOG_MESS_07_1="Cloning additional TMUX stuff"
LOG_MESS_07_1_a="Not updating submodules"
LOG_MESS_07_1_b="Submodules updated!"
LOG_MESS_07_2="gvimrc doesn't exist"
LOG_MESS_07_3="Added line for .tmux-git to .bashrc"
LOG_MESS_08="Cloning VÍM and submodules"
LOG_MESS_09="\nDone setting up ~/dotfiles"

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
###     ^NO Editing below this line ^
###    Tracedebug
#
if [ $trace_debug -eq 1 ]; then
    set -x
    trap read debug
fi

unalias -a

###     Delete old log and create new
#
function date_it() {
    rm -f ${LOG}
    touch ${LOG}
    #[[ $debug -eq 1 ]] && printf "\n$TITLE - $DATE\n"; sleep ${SLEEP}
    [[ $debug -eq 1 ]] && printf "\n$TITLE - $DATE\n" || printf "\n$TITLE - $DATE\n" >> $LOG; sleep ${SLEEP}
}

###     Function for updating submodules
#
function submodules_init() {
    git submodule init && git submodule update
}

function submodules_update() {
    git submodule foreach git pull origin master
}

function app_installer() {
    ###     Installs software
    #
    for APP in "${APPARRAY[@]}"
    do
        #echo $APP
        if command -v $APP >/dev/null 2>&1 ; then
            STATUS="$APP already installed!"
        elif ! [ -x command -v $APP >/dev/null 2>&1 ]; then
           sudo apt install $APP
            STATUS="Installing $APP"
        else
            STATUS="$APP failed to install!"
        fi
        [[ $debug -eq 1 ]] && echo "$STATUS"  || echo "$STATUS" >> $LOG; sleep ${SLEEP}
    done 
}

function copy_old_files() {
    # copies old dotfiles to backup folder
    for OLDFILE in "${OLDFILEARRAY[@]}"
        do
            cp ~/"$OLDFILE" $DIR/ 2>/dev/null
            [[ $debug -eq 1 ]] && echo "$OLDFILE moved to $DIR" || echo "$OLDFILE moved to $DIR" >> ${LOG} ; sleep ${SLEEP}
        done
}

function archive_it() {
    ### Archive the old files if there are any
    #
    if [ -n "$(find ${DIR} -prune -empty 2>/dev/null)" ]; then
        FILE_STATUS="File or directory empty. Nothing to archive!"
    else
        zip -r -q -u -m $DIR/"$FILE" $DIR -x "*.zip" && FILE_STATUS="Files compressed ok!" || FILE_STATUS="Files not compressed!"
    fi
    [[ $debug -eq 1 ]] && echo "$LOG_MESS_06" || echo "$LOG_MESS_06" >> ${LOG}; sleep ${SLEEP}
    [[ $debug -eq 1 ]] && echo "$FILE_STATUS" || echo "$FILE_STATUS" >> ${LOG} ; sleep ${SLEEP}
}

function sym_link_check() {
    ###     Check for old (sym)links
    for LINK in "${DOTARRAY[@]}"
    do
    ###     Test if files are symlimked or not
        if [ -L "${LINK}" ] ; then
           if [ -e "${LINK}" ] ; then
                ### Found link
                LINK_STATUS="removing $LINK" 
                rm -f "$LINK" 
            else
                ### Broken link
                LINK_STATUS="Broken link: $LINK, removing it!"
                rm -f "$LINK"
             fi
        elif [ -e "${LINK}" ] ; then
            ### Broken link
            LINK_STATUS="$LINK is not a symlink. Moving it" 
            mv "$LINK" $DIR
        else
            ### Missing link
            LINK_STATUS="Missing: $LINK. Symlinking it!"
            ln -s ~/dotfiles/"$LINK" ~/
            #[[ $debug -eq 1 ]] && echo "updating submodules" || echo "updating submodules"; sleep ${SLEEP}
        fi
        [[ $debug -eq 1 ]] && echo "$LINK_STATUS" || echo "$LINK_STATUS" >> ${LOG} ; sleep ${SLEEP}
    done
}

function get_os() {
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

function setting_standard_commands() {
    case $OSSYS in
        solaris*) 
            [[ $debug -eq 1 ]] && echo "Setting alias' for: Solaris" || echo "Setting alias' for: Ssolaris" >> $LOG; sleep ${SLEEP}
            alias install="pkg install" $1
            alias {uninstall,remove}="pkg uninstall" $1
            alias app_search="pkg search" $1
            alias update="pkg update --accept" 
            ;;
        darwin*)  
            [[ $debug -eq 1 ]] && echo "Setting alias' for: OSX" || echo "Setting alias' for: OSX" >> $LOG; sleep ${SLEEP}
            ;; 
        debian*)   
            [[ $debug -eq 1 ]] && echo "Setting alias' for: LINUX (Debian)" || echo "Setting alias' for: LINUX (Debian)" >> $LOG; sleep ${SLEEP}
            #alias rm='rm -i' 
            alias install="apt-get install" $1
            alias {uninstall,remove}="sudo apt remove"
            alias apt_update="sudo aptitude update"
            alias {sys_update,update,sysupdate}="sudo apt-get update && sudo apt-get upgrade"
            alias sysclean="sudo apt clean; sudo apt autoremove; sudo apt purge"
            ;;
        *bsd) 
            [[ $debug -eq 1 ]] && echo "Setting alias' for: *BSD" || echo "Setting alias' for: *BSD" >> $LOG; sleep ${SLEEP}
            alias install="pkg install" $1
            alias {uninstall,remove}="pkg delete" $1
            alias {sys_update,sysup,sysupdate}="freebsd-update fetch && freebsd-update install"
            alias upgrade="pkg update && pkg upgrade"
            alias autoclean="pkg autoremove"
            alias clean="pkg clean -c"
            unalias ll; alias ll="";;
        redhat*)                                                           #     YUM (RedHat Linux, centos)
            [[ $debug -eq 1 ]] && echo "Setting alias' for: RedHat" || echo "Setting alias' for: RedHat" >> $LOG; sleep ${SLEEP}
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
            [[ $debug -eq 1 ]] && echo "Setting alias' for: OpenSuSe" || echo "Setting alias' for: OpenSuSe" >> $LOG; sleep ${SLEEP}
            alias install="zypper install" $1
            alias {uninstall,remove}="zypper remove" $1
            alias app_search="zypper search" $1
            alias update="sudo zypper refresh; sudo zypper dup"
            alias sysclean="sudo zypper clean -a"
            alias dist_upgrade="sudo zypper dist-upgrade"
            ;;
        fedora*)                                                           #        Fedora
            [[ $debug -eq 1 ]] && echo "Setting alias' for: Fedora" || echo "Setting alias' for: Fedora" >> $LOG; sleep ${SLEEP}
            alias install="dnf install" $1
            alias {uninstall,remove}="dnf remove" $1
            alias upgrade="dnf upgrade"
            alias search="dnf search" $1
            alias autoremove="dnf remove" $1
            alias sysclean="dnf clean all"
            ;;
        pacman*)                                                           #        ArchLinux
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ArchLinux" || echo "Setting alias' for: ArchLinux" >> $LOG; sleep ${SLEEP}
            alias install="pacman -Syu" $1
            alias {uninstall,remove}="pacman -Rsc" $1
            alias force_install="pacman -S --force" $1
            alias reinstall="pacman -Syu $(pacman -Qqen)"
            alias update="pacman -Syu"
            alias sysclean="pacman -Sc"
            alias package_list="pacman -Q"
            ;;
        msys*)    
            [[ $debug -eq 1 ]] && echo "Setting alias' for: CygWIN" || echo "Setting alias' for: CygWIN" >> $LOG; sleep ${SLEEP}
            ;;
        *)        
            [[ $debug -eq 1 ]] && echo "Unknown OS!" || echo "Unknown OS!" >> $LOG; sleep ${SLEEP} 
            ;;
    esac
}

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     On first run. This is a quick and dirty script, no backups or questions asked!

###     Create  logfile
#
date_it
[[ $debug -eq 1 ]] && echo "$LOG_MESS_01" || echo "$LOG_MESS_01" >> ${LOG}; sleep ${SLEEP}

###     Removing all old aliases
#
unalias -a
[[ $debug -eq 1 ]] && echo "Done unalias'" || echo "Done unalias'" >> ${LOG}; sleep ${SLEEP}
###     Check for apps, install if not found
#
app_installer

###     Check what os this is running on
#
get_os
[[ $debug -eq 1 ]] && printf "$LOG_MESS_01_1\n" || printf "$LOG_MESS_01_1\n" >> ${LOG}; sleep ${SLEEP}
[[ $debug -eq 1 ]] && printf "OS=$OS\nDIST=$DIST\nDistroBasedOn=$DistroBasedOn\n" || printf \
"OS=$OS\nDIST=$DIST\nDistroBasedOn=$DistroBasedOn\n\n" >> ${LOG}; sleep ${SLEEP}

###     Setting up aliases for specific os'
#
setting_standard_commands
[[ $debug -eq 1 ]] && printf "Added aliases for $OSSYS-based system!\n" || printf "Added aliases for $OSSYS-based system!\n" >> ${LOG}; sleep ${SLEEP}

###     Feth any updates to the dotfiles repo
#
git pull origin master

###     Ask confirmation for github
#
read -p "Update all repos (y/n)?" 
if [ "$x" = "yes" ]
then
 ###     If debug mode is on (=1) then don't fetch submodules, faster
#
[[ $debug -eq 1 ]] && echo "Not fetching submodules" || submodules_init; echo "Submodules added!" >> ${LOG}
#[[ $debug -eq 1 ]] && echo "ran submodules_init" ; sleep ${SLEEP}
[[ $debug -eq 1 ]] && echo "Not updating submodules" || submodules_update; echo "Submodules updated!" >> ${LOG}
fi

###     Create backup dir
#
mkdir $DIR 2> /dev/null
[[ $debug -eq 1 ]] && echo "$LOG_MESS_03 $DIR" || echo "$LOG_MESS_03 $DIR" >> ${LOG} ; sleep ${SLEEP}

###     Moving/Copying old files
#
copy_old_files
ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile
[[ $debug -eq 1 ]] && echo "$LOG_MESS_05" || echo "$LOG_MESS_05" >> ${LOG}; sleep ${SLEEP}

###     Archive old files (Not necessary?)
#
archive_it

###     Clone tmux repo
#
git clone --recurse-submodules git@bitbucket.org:b0red/tmux.git ~/.tmux; cd ~/.tmux
[[ $debug -eq 1 ]] && echo "$LOG_MESS_07" || echo "$LOG_MESS_07" >> ${LOG}; sleep ${SLEEP}
[[ $debug -eq 1 ]] && echo "Not updating submodules! (TMUX)" || submodules_update; echo "Submodules updated! (TMUX)" >> ${LOG}
ln -s ~/.tmux/.tmux.conf ~/.tmux.conf


###     Clone additional tmux stuff
#
#git clone git://github.com/drmad/tmux-git.git ~/.tmux-git
#git clone git://github.com/arl/tmux-gitbar ~/.tmux-gitbar
ln -s extras/tmux-git.git ~/.tmux-git
ln -s extras/tmux-gitbar ~/.tmux-gitbar
#[[ $debug -eq 1 ]] && echo "$LOG_MESS_07_1" || echo "$LOG_MESS_07_1" >> ${LOG}; sleep ${SLEEP}


###     Check if line exists in file .bashrc, if not copy it
#
grep -qxF "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" ~/.bashrc
if [ $? -ne 0 ]; then
    echo "if [[ \$TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi" >> ~/.bashrc
    [[ $debug -eq 1 ]] && echo "$LOG_MESS_07_3" || echo "$LOG_MESS_07_3" >> ${LOG}; sleep ${SLEEP}
else
    STATUS="Line not added!";  echo $STATUS
fi

###     Clone vim repo & submodules & symlink files
#
git clone --recurse-submodules git@bitbucket.org:b0red/.vim.git ~/.vim; cd ~/.vim
[[ $debug -eq 1 ]] && echo "$LOG_MESS_07_1_a" || submodules_update; echo "$LOG_MESS_07_1_b" >> ${LOG}
ln -s ~/.vim/vimrc ~/vimrc; 
[[ -f ~/.vim/gvimrc ]] && ln -s ~/.vim/gvimrc ~/gvimrc; echo "Symlinked gvimrc" || echo "$LOG_MESS_07_2"; \
echo "$LOG_MESS_07_2" >> ${LOG}
[[ $debug -eq 1 ]] && echo "$LOG_MESS_08" || echo "$LOG_MESS_08" >> ${LOG}; sleep ${SLEEP}

 
###     Source .bashrc
#
source  ~/.bashrc

echo "$LOG_MESS_09"

# ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     Show summary of what was done
#
sleep 5
#clear; 
printf "\n====== Summary ======\nResult of $TITLE"
cat ${LOG}
sleep ${SLEEP}
[[ ! $debug -eq 1 ]] && exit 0
    
## ~--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
###     Debuginfo - just printing  values to screen
#
if [ $debug -eq 1 ]; then
    clear
    printf "\n$TITLE"
    printf "\nOutput from:${ORANGE} ${0##*/} ${NC} \n"
    printf "Hostname:          $HOSTNAME\n"
    printf "BackupDIR:         $DIR"
    printf "Oldfiles:          $OLDFILES"
    printf "File:              $FILE"
    printf "Folderpath:        $DIR/$HOSTNAME\n"
    printf "Archive status:    $FILE_STATUS"
    printf "Archive name:      $ARCHIVE"
    printf "Logfile:           ${LOG}"
    printf "Date:              $DATE\n"
    printf "DistroBasedOn:     $DistroBasedOn"
fi
exit 0
