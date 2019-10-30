#!/bin/bash -p
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export TERM=${TERM:-dumb}
export DISPLAY=:0.0
###################################################################################################################
##
##                   W A R N I N G !  - You ar running this at your own risk -  W A R N I N G ! 
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
##          v3.0
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
###################################################################################################################
clear

#
# +-+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
#

###     Debug on/off  - Change for debugging purposes
#
debug=0                                             # Debug 1 = echo to screen / 0 = echo to logfile
trace_debug=0
SLEEP=2                                             # Sleeptimer

###     Settings - Change if you need to
#
DIR=~/dotfiles/oldfiles                             # Where to store old backuped files
OLDFILES=oldfiles.txt                               # Filelist - not in use right now
ARCHIVE="$FILE"                                     # Arhchive name
LOG=~/dotfiles/oldfiles/install_progress_log        # Installation prograss log
DATE=$(date +"%Y-%m-%d %H:%M:%S")                   # Date - for zipfile
TITLE="Dotfiles Installer Script"                   # scriptname
FILE="$HOSTNAME-$DATE.zip"                          # Filename

###     Software array
#
APPARRAY=(curl htop ncdu pydf tree tmux vim mc)     # Apps to be installed - add if you like
DOTARRAY=(~/.profile ~/.bashrc ~/.bash_profile ~/.inputrc)                         # old dotfiles
OLDFILEARRAY=(~/.bashrc ~/.profile ~/.bash_profile ~/.inputrc ~/.cshrc ~/.login)
#SUBMODULES=(https://github.com/denilsonsa/prettyping.git https://github.com/tlatsas/bash-spinner.git) #s submodules for git repos

###     LogMessages
#
LOG_MESS_001="Done unaliasing!"
LOG_MESS_01="Ran function date_it."
LOG_MESS_01_1="Checking for OS type and found:"
LOG_MESS_02="Setting appropriate aliases for this system." 
LOG_MESS_03="Created backup dir: "
LOG_MESS_04="Ran function 'app_installer'"
LOG_MESS_05="Symlinked the new dotfiles!"
LOG_MESS_06="Ran function 'archive_it'"
LOG_MESS_07="Cloning TMUX and submodules"
LOG_MESS_07_1="Cloning additional TMUX stuff"
LOG_MESS_07_1_a="Not adding/updating submodules"
LOG_MESS_07_1_b="Submodules added/updated!"
LOG_MESS_07_2="gvimrc doesn't exist"
LOG_MESS_07_3="Added line for .tmux-git to .bashrc"
LOG_MESS_08="Cloning VÍM and submodules"
LOG_MESS_09="Done setting up ~/dotfiles"
LOG_MESS_091_a="Files compressed ok!"
LOG_MESS_091_b="Files not compressed!"
LOG_MESS_092="File or directory empty. Nothing to archive!"

# +-+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
###     ^NO Editing below this line ^

###    Tracedebug
#
if [ $trace_debug -eq 1 ]; then
    set -x
    trap read debug
fi

#[[ $debug -eq 1 ]] && echo "$LOG_MESS_001" || echo "$LOG_MESS_001" >> ${LOG}; sleep ${SLEEP}

## #     Ensure script is not being run with root privileges
#
if [ $EUID -eq 0 ]; then
    echo "Please don't run this script with root privileges!"
    exit 1
fi
#
# +-+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
#
function init() {
    if [ $# -gt 0 ]; then
        case "$1" in
            -h|--help)
                usage
                exit 1
                ;;
            *)
                echo -e "ERROR: Unrecognized parameter: '${1}'\nSee usage (--help) for options..." 1>&2
                exit 1
                ;;
        esac
    fi
}

function check_for_line(){
     #grep -qxF "#All your base are belong to ${DistroBasedOn^}" ~/.bashrc
    grep -E "#All your base are belong to ${DistroBasedOn^}" ~/.bashrc
    if [ $? -ne 0 ]; then
        echo "#All your base are belong to ${DistroBasedOn^}" >> ~/.bashrc
        STATUS="Added to ~/.bashrc!"
    else
        STATUS="Was not added to ~/.bashrc!";  
    fi
}

function date_it() {
    ###     Delete old log and create new
    rm -f ${LOG}; touch ${LOG}
    [[ $debug -eq 1 ]] && printf "\n$TITLE - $DATE\n" || printf "\n$TITLE - $DATE\n" >> $LOG; sleep ${SLEEP}
    [[ $debug -eq 1 ]] && echo "$LOG_MESS_01" || echo "$LOG_MESS_01" >> ${LOG}; sleep ${SLEEP}
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
    # Installs apps/software
    for APP in "${APPARRAY[@]}"
    do
        #echo $APP
        if command -v $APP >/dev/null 2>&1 ; then
            STATUS="$APP already installed!"
        elif ! [ -x command -v $APP >/dev/null 2>&1 ]; then
            install $APP
            STATUS="Installing $APP"
        else
            STATUS="$APP failed to install!"
        fi
        [[ $debug -eq 1 ]] && echo "$STATUS"  || echo "$STATUS" >> $LOG; sleep ${SLEEP}
    done 
}

function copy_old_files() {
    # copies old dotfiles to backup folder
    if [ ! -d $DIR ]; then 
        ###     Create backup dir
        mkdir $DIR 2> /dev/null
        [[ $debug -eq 1 ]] && echo "$LOG_MESS_03 $DIR" || echo "$LOG_MESS_03 $DIR" >> ${LOG} ; sleep ${SLEEP}
    fi
    for OLDFILE in "${OLDFILEARRAY[@]}"
    do
        cp ~/."$OLDFILE" "$OLDFILE".bak
        #mv ~/"$OLDFILE" $DIR/ 2>/dev/null
        [[ $debug -eq 1 ]] && echo "$OLDFILE backed up and moved to $DIR" || echo "$OLDFILE backed up and moved to $DIR" >> ${LOG} ; sleep ${SLEEP}
    done
}

function symlink_us(){
    # Symlink files
    ln -s ~/dotfiles/.bashrc ~/.bashrc; ln -s ~/dotfiles/.profile ~/.profile
    [[ $debug -eq 1 ]] && echo "$LOG_MESS_05" || echo -e "\n$LOG_MESS_05" >> ${LOG}; sleep ${SLEEP}
}

function archive_it() {
    ### Archive the old files if there are any
    if [ -n "$(find ${DIR} -prune -empty 2>/dev/null)" ]; then
        FILE_STATUS="$LOG_MESS_092"
    else
        zip -r -q -u -m $DIR/"$FILE" $DIR -x "*.zip" && FILE_STATUS="$LOG_MESS_091_a" || FILE_STATUS="$LOG_MESS_091_b"
    fi
    [[ $debug -eq 1 ]] && echo "$LOG_MESS_06" || echo "$LOG_MESS_06" >> ${LOG}; sleep ${SLEEP}
    [[ $debug -eq 1 ]] && echo "$FILE_STATUS" || echo "$FILE_STATUS" >> ${LOG} ; sleep ${SLEEP}
    [[ $debug -eq 1 ]] && echo "Created $FILE" || echo -e "Created $FILE\n" >> ${LOG} ; sleep ${SLEEP}    
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


function get_repos() {
    ###     Ask confirmation for github
    #
    #read -p "Update all repos (y/n)?" 
    #if [ "$x" = "yes"  ]; then
        ###     Clone tmux repo
        #
        git clone --recurse-submodules git@bitbucket.org:b0red/tmux.git ~/.tmux; cd ~/.tmux
        ln -s ~/.tmux/.tmux.conf ~/.tmux.conf
        submodules_init; submodules_update
        [[ $debug -eq 1 ]] && echo "$LOG_MESS_07" || echo "$LOG_MESS_07" >> ${LOG}; sleep ${SLEEP}

        ###     Clone .vim repo
        #
        git clone --recurse-submodules git@bitbucket.org:b0red/.vim.git ~/.vim; cd ~/.vim
        [[ $debug -eq 1 ]] && echo "$LOG_MESS_07_1_a" || submodules_update; echo "$LOG_MESS_07_1_b" >> ${LOG}
        ln -s ~/.vim/vimrc ~/vimrc 
        if [ -f ~/.vim/gvimrc ]; then
            ln -s ~/.vim/gvimrc ~/gvimrc
        fi
        submodules_init; submodules_update
        [[ $debug -eq 1 ]] && echo "$LOG_MESS_08" || echo "$LOG_MESS_08" >> ${LOG}; sleep ${SLEEP}
            
        ln -s ~/dotfiles/extras/tmux-git.git ~/.tmux-git
        ln -s ~/dotfiles/extras/tmux-gitbar ~/.tmux-gitbar

    #fi
}

function add_line(){
        ###     Check if line exists in file .bashrc, if not copy it
        grep -qxF "if [[ $TMUX ]]; then source ~/.tmux/extras/tmux-git/tmux-git.sh; fi" ~/.bashrc
        if [ $? -ne 0 ]; then
            echo "if [[ $TMUX ]]; then source ~/.tmux/extras/tmux-git/tmux-git.sh" >> ~/.bashrc
            [[ $debug -eq 1 ]] && echo "$LOG_MESS_07_3" || echo "$LOG_MESS_07_3" >> ${LOG}; sleep ${SLEEP}
        else
            STATUS="Line '~/.tmux-git/tmux-git.sh' was not added to ~/.bashrc!";  echo $STATUS
        fi
}

function check_for_line(){
        grep -qxF "#All your base" ~/.bashrc
        if [ $? -ne 0 ]; then
            echo "echo "#All your base are belong to ${DistroBasedOn^}" >> ~/.bashrc" >> ~/.bashrc
            [[ $debug -eq 1 ]] && echo "$LOG_MESS_07_3" || echo "$LOG_MESS_07_3" >> ${LOG}; sleep ${SLEEP}
        else
            STATUS="Was not added to~/.bashrc!";  echo $STATUS
        fi
}

function get_os() 
{
    #checks for os tyoe, this to alias right things
    OS=$(uname); OS="${OS,,}"
    KERNEL=$(uname -r)
    MACH=$(uname -m)
    if [ "${OS}" == "windowsnt" ]; then
        OS=windows; OSSYS="windows"
    elif [ "${OS}" == "darwin" ]; then
        OS=mac; OSSYS="darwin"
    elif [ "${OS}" == "freebsd" ]; then
        OS=bsd; OSSYS="bsd"
        OSSTR=$(uname -rs)
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
                DistroBasedOn='Mandrake'; OSSYS="mandriva"
                PSEUDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
                REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
            elif [ -f /etc/debian_version ] ; then
                DistroBasedOn='Debian'; OSSYS="debian"
                DIST=$(cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
                PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
                REV=$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')
            elif [ -f /etc/sabayon-edition ] ; then
                DistroBasedOn='Gentoo'; OSSYS="gentoo"
                DIST=$(cat /etc/*-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
                #PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
                REV=$(cat /etc/sabayon-edition | grep -Eo '[0-9][0-9]'.'[0-9][0-9]')    
            fi
            if [ -f /etc/UnitedLinux-release ] ; then
                DIST=$(${DIST}["cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//"])
                OSSYS="unitedlinux"
            fi
            OS="${OS,,}"
            DistroBasedOn="${DistroBasedOn,,}"
            #readnly make varaible readonly
            # readonly OS
            # readonly DIST
            # readonly DistroBasedOn
            # readonly PSEUDONAME
            # readonly REV
            # readonly KERNEL
            # readonly MACH
            # readonly OSSYS
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

function setting_standard_commands() 
{
    case $OSSYS in
        solaris*)                                                           # Solaris
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias install="pkg install" $1
            alias {uninstall,remove}="pkg uninstall" $1
            alias app_search="pkg search" $1
            alias update="pkg update --accept"
            check_for_line
            os_status="solaris"
            ;;
        redhat*)                                                           #     YUM (RedHat Linux, centos)
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            #PATH=$PATH:$HOME/bin
            alias install="sudo yum install -y" $1
            alias {uninstall,remove}="sudo yum remove" $1
            alias update="sudo yum update -y"
            alias upgrade="sudo yum upgrade -y"
            alias swap="sudo yum swap" $1 $2
            alias autoremove="sudo yum autoremove" $1
            alias reinstall="sudo yum reinstall" $1
            check_for_line
            os_status="redhadt"
            ;;
        suse*)                                                            #     OpenSuSe)
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias install="zypper install" $1
            alias {uninstall,remove}="zypper remove" $1
            alias app_search="zypper search" $1
            alias update="sudo zypper refresh; sudo zypper dup"
            alias sysclean="sudo zypper clean -a"
            alias dist_upgrade="sudo zypper dist-upgrade"
            check_for_line
            os_status="suse"
            ;;
        mandriva*)                                                          # Mandrake/Mandriva
            ;;
        debian*)                                                            # Ubuntu and derivates
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            #alias rm='rm -i' 
            # Upgrade
            alias apt_update="sudo aptitude update"
            # install
            alias install="apt install" $1
            alias {uninstall,remove}="sudo apt remove && sudo apt autoremove"
            alias {sys_update,update,sysupdate}="sudo apt-get update && sudo apt-get upgrade -y && sudo apt autoremove && sudo apt autoremove"
            alias sysclean="apt clean; sudo apt autoremove; sudo apt purge"
            alias installf="apt -f install" #force install
            alias reinstall="apt -f install --reinstall" # Force reinstall
            # Cleaning
            alias clean="apt clean && sudo apt autoclean"
            alias purge="apt purge"
            alias deborphan="deborphan | xaargs sudo apt -y remove --purge"
            # Network Start, Stop, and Restart
            alias networkrestart="sudo service networking restart"
            alias networkstop="sudo service networking stop"
            alias networkstart="sudo service networking start"
            check_for_line
            os_status="Debian"
            ;;
        gentoo*)
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias repo_update="emerge --sync"
            alias update="emerge --update --deep --ask @world"
            alias sysupdate="emerge --update --deep --with-bdeps=y --newuse @world"
            alias cleanupdate="emerge --update --deep --newuse @world && emerge --depclean &&  revdep-rebuild"
            alias app_search="emerge --search " $1
            alias {remove,uninstall}="emerge --unmerge " $1
            check_for_line
            os_status="Gentoo"
            ;;
        darwin*)  
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            check_for_line
            os_status="Mac/Darwin"
            ;; 
        *bsd) 
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias install="pkg install " $1
            alias {uninstall,remove}="pkg deletei " $1
            alias {sys_update,sysup,sysupdate}="freebsd-update fetch && freebsd-update install"
            alias upgrade="pkg update && pkg upgrade"
            alias autoclean="pkg autoremove"
            alias clean="pkg clean -c"
            check_for_line
            check_for_lineos_status="*bsd"
            ;;
        fedora*)                                                           #        Fedora
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias install="dnf install" $1
            alias {uninstall,remove}="dnf remove" $1
            alias upgrade="dnf upgrade"
            alias app_search="dnf search" $1
            alias autoremove="dnf remove" $1
            alias sysclean="dnf clean all"
            check_for_line
            os_status="fedora"
            ;;
        pacman*)                                                           #        ArchLinux
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias install="pacman -Syu" $1
            alias {uninstall,remove}="pacman -Rsc" $1
            alias force_install="pacman -S --force" $1
            alias reinstall="pacman -Syu $(pacman -Qqen)"
            alias update="pacman -Syu"
            alias sysclean="pacman -Sc"
            alias package_list="pacman -Q"
            check_for_line
            os_status="pacman"
            ;;
        msys*)    
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            check_for_line
            os_status="MS Windows"
            ;;
        *)        
            [[ $debug -eq 1 ]] && echo "Unknown OS!" || echo "Unknown OS!" >> $LOG; sleep ${SLEEP} 
            check_for_line
            os_status="I have no clue"
            ;;
    esac
}

function show_summary() {
    sleep 5
    printf "\n====== Summary ======\nResult of $TITLE"
    cat ${LOG}
    sleep ${SLEEP}
#[[ ! $debug -eq 1 ]] && exit 0
}
# --+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     On first run. This is a quick and dirty script, no backups or questions asked!

###     Create  logfile
#
date_it

###     Moving/Copying old files
#
copy_old_files

###     Delete old symlinks
#
sym_link_check

###     Symlink new files
#
symlink_us

###     Check what os this is running on
#
get_os

###     Check for apps, install if not found
#
app_installer

###     Archive old files 
#
archive_it

###     Get subrepos
#
get_repos

###     Add line about tmux to ~/.bashrc
#
add_line

###     Source .bashrc
#
source  ~/.bashrc

###     Setting up aliases for specific os
#
setting_standard_commands

###     Run shit here
#init "$@"
#sanity
#install

echo "$LOG_MESS_09"

# --+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+

###     Show summary of what was done
#
show_summary

## -+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++--+--+--+--+--++--+--+--+--+--+
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

    echo "function: get_os"; get_os
    echo "function: standard_commands"; setting_standard_commands

    echo -e "\nOS:                   ${OS^} "
    echo -e "DistroBased on:       ${DistroBasedOn^}"

    echo "Dist:                 ${DIST^}"
    echo "Rev:                  ${REV^}"
    echo "PSEUDONAME:           ${PSEUDONAME^}"
    echo "os_status:            $os_status"
fi
exit 0
