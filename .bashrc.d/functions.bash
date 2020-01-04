# ---------------------------------------------------------------------------------
#
#	.bash_functions
#
# ---------------------------------------------------------------------------------

###     Define  & source colors
#
# if [[ $TMUX ]]; then source ~/.tmux-git/tmux-git.sh; fi
[[ -f $HOME/bin/ColorCodes.inc ]]  && source $HOME/bin/ColorCodes.inc        #For printing output i pretty colors
[[ -f $HOME/bin/spinner.sh ]]  && source $HOME/bin/spinner.sh                #Running a spinner for long commands

#not an alias, but I thought this simpler than the cd control
#If you pass no arguments, it just goes up one directory.
#If you pass a numeric argument it will go up that number of directories.
#If you pass a string argument, it will look for a parent directory with that name and go up to it.
function up()
{
    dir=""
    if [ -z "$1" ]; then
        dir=..
    elif [[ $1 =~ ^[0-9]+$ ]]; then
        x=0
        while [ $x -lt ${1:-1} ]; do
            dir=${dir}../
            x=$(($x+1))
        done
    else
        dir=${PWD%/$1/*}/$1
    fi
    cd "$dir";
}
###	Create dir and enter it
#
function mcd () { # Makes a directory and enters it
    [ -z "$1" ] && { echo "Usage: 'mcd <directory name> (Need to be root if outside of $HOME)'" >&2; return; }
    mkdir -p "$1" && 
        cd "$1"
}

###	Startbitbucket - creates remote bitbucket repo and adds it as git remote to cwd
#
function startbitbucket () # Creates a remote bitbucketrepo & adds it as a git remote
{
    #echo 'Username?'
    #read username
    #echo 'Password?'
    #read -s password  # -s flag hides password text
    echo 'Repo name?'
    read reponame
    username="b0red";password="AxREYw2WNEKj8YxTrRBt" 
    curl --user $username:$password https://api.bitbucket.org/1.0/repositories/ --data name=$reponame --data is_private='true'
    git remote add origin git@bitbucket.org:$username/$reponame.git
    git push -u origin --all
    git push -u origin --tags
}

###	Find file by exact name recursively.
#       Usage: ff (file)
function ff() {
    if [ -z "$1" ]; then
        echo "Usage: 'ff <filename to search for>'"
        return 1
    else
        #[[ -f $HOME/bin/spinner.sh ]]  && start_spinner 'searching...'
        echo "searching for: $1"
        find . -name "$1"
        #[[ -f $HOME/bin/spinner.sh ]]  && stop_spinner $?
    fi
}

###     Allows you to search for any text in any file recursively.
#       Usage: ft "my string" *.php
function fif() {
    if [ -z "$1" ]; then
        echo "Usage: Enter 'fif <text>' to search for in files recursevly from current location which is: $PWD"
        return 1
    else
        echo "searching for\'$1\' in \'$PWD\'"
        #start_spinner 'searching...'
        grep --exclude-dir='.git|~/.ssh' -Ril . -e "$1"
        #stop_spinner $?
        # find . -maxdepth 2 -type f -exec grep "$1" '{}' \;
        #find . -maxdepth 2 -type f exec -exec grep -il "$1" {} \;
    fi
}

###     Search for command in history.
#       Usage: hs (string)
function hs() {
    if [ -z "$1" ]; then
        echo "Usage: 'hs <command to search for.>'"
    else
        history | grep "$1"
    fi
}

###	    Extract most know archives
#
function extract() {
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
        echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
        return 1
    else
        for n in $@
        do
            if [ -f "$n" ] ; then
                case "${n%,}" in
                    *.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar) 
                        tar xvf "$n"       ;;
                    *.lzma)      unlzma ./"$n"      ;;
                    *.bz2)       bunzip2 ./"$n"     ;;
                    *.rar)       unrar x -ad ./"$n" ;;
                    *.gz)        gunzip ./"$n"      ;;
                    *.zip)       unzip ./"$n"       ;;
                    *.z)         uncompress ./"$n"  ;;
                    *.7z|*.arj|*.cab|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.rpm|*.udf|*.wim|*.xar)
                        7z x ./"$n"        ;;
                    *.xz)        unxz ./"$n"        ;;
                    *.exe)       cabextract ./"$n"  ;;
                    *)
                        echo "extract: '$n' - unknown archive method"
                        return 1
                        ;;
                esac
            else
                echo "'$n' - file does not exist"
                return 1
            fi
        done
    fi
}

###	    Debug
#
function debug() {
    bash -x "$1"
}


###	    Creates an archive (*.tar.gz) from given directory.
#
function maketar() {
    if [ $# -ne 1 ]; then
        echo "Usage: maketar <filename to create> <folder to compress>"
    fi
        tar -cvzf "${1%%/}.tar.gz"  "${1%%/}/";
}

###	    Creates an archive (*.tar.bz2) from given directory.
#
function makejar() {
    if [ $# -ne 1 ]; then
        echo "Usage: makejar <filename to create> <folder to compress>"
    fi
    tar -cjf "${1%%/}.tar.bz2"  "${1%%/}/";
}

###	    Create a ZIP archive of a file or folder.
#
function makezip() {
    if [ $# -ne 1 ]
    then
        echo "Usage: makezip  <filename to create>.zip <folder to zip>"
        #exit 0 
    fi
    #zip -r "${1%%/}.zip" "$1" ;
    zip -r "${1}.zip" "$2"
}

###	    Reconnect or start a tmux or screen session over ssh
#
function sssh () {
    ssh -t "$1" 'tmux attach || tmux new || screen -DR';
}

###	    Copy public key to remote machine (dependency-less)
#
function authme() {
    echo Server?
    read server
    # ssh "$1" 'mkdir -p ~/.ssh && cat #>> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
    ssh $server 'mkdir -p ~/.ssh && cat #>> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
}

###	    Paginated colored tree
#
function ltree() {
    tree -C $* | less -R
}

###	    CD and ls a directory
#
function cdl () {
    if [ -z "$1" ]; then
        echo "Usage: 'cdl <folder to enter and list>'"
    else
        cd $1; ls
    fi
}

###	    Find a pattern in a set of files and highlight them:
#	    + (needs a recent version of egrep).
function fstr() {
    OPTIND=1
    local mycase=""
    local usage="fstr: find string in files.
    Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt
    do
        case "$opt" in
            i) mycase="-i " ;;
            *) echo "$usage"; return ;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
    find . -type f -name "${2:-*}" -print0 | \
        xargs -0 egrep --color=always -sn ${case} "$1" 2>&- | more
}

###	    Pretty-print of 'df' output.
#	    Inspired by 'dfc' utility.
function mydf() {
    if [ -z "$1" ]; then
        echo "Usage: 'mydf <folder>'"
    else
        for fs ; do
            if [ ! -d $fs ]
            then
                echo -e $fs" :No such file or directory" ; continue
            fi
            local info=( $(command df -P $fs | awk 'END{ print $2,$3,$5 }') )
            local free=( $(command df -Pkh $fs | awk 'END{ print $4 }') )
            local nbstars=$(( 20 * ${info[1]} / ${info[0]} ))
            local out="["
            for ((j=0;j<20;j++)); do
                if [ ${j} -lt ${nbstars} ]; then
                    out=$out"*"
                else
                    out=$out"-"
                fi
            done
            out=${info[2]}" "$out"] ("$free" free on "$fs")"
            echo -e $out
        done
    fi
}

###	    Get current host related info.
#
function ii() {
    echo -e "\nThis is ${ORANGE}$HOSTNAME$NC"
    echo -e "\n${ORANGE}Additionnal information:${NC} " ; uname -a
    echo -e "\n${ORANGE}Users logged on:$NC " ; w -hs | cut -d " " -f1 | sort | uniq
    echo -e "\n${ORANGE}Current date :$NC " ; date
    echo -e "\n${ORANGE}Machine stats :$NC " ; uptime
    echo -e "\n${ORANGE}Memory stats :$NC " ; free -h
    echo -e "\n${ORANGE}Diskspace :$NC " ; mydf / $HOME
    echo -e "\n${ORANGE}Local IP Address :$NC" ; myip
    echo -e "\n${ORANGE}Open connections :$NC "; netstat -pan --inet;
    echo
}

###	    Get IP adress on ethernet.
#
function myip() {
    #MY_IP=$(/sbin/ifconfig eth0 | awk '/inet/ { print $2 } ' | sed -e s/addr://)
     MY_IP=$(/sbin/ifconfig $(getnic) | awk '/inet / { print $2 } ' | sed -e s/addr://| tr '' '/n' |sort)
    #echo -e "$MY_IP"
    #echo -e ${MYP_IP}
    printf '%s\n' ${MY_IP:-"Not connected"}
}

###     Get active Network Interface
#
function getnic() { 
    nic=$(sudo ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
    if [ ! -z "$1" ]; then
        echo "NIC: $nic"
    fi
}

###	Send pushover messages
#   https://www.reddit.com/r/pushover/comments/1ezepb/howto_using_wget_instead_of_curl_to_send_pushover/
#   Not working right now
function pushover() {
    source $HOME/bin/email_variables.inc 
    wget -q \
        --post-data="token=$APP_TOKEN \ 
        &user=$USER_KEY \
        &title=$(uname -n) says: \ 
        # &priority=PPPP \
        # &retry=RRRR \
        # &expire=EEEE \ 
        # &sound=SSSSSS \ 
        &message=$1" \
        https://api.pushover.net/1/messages.json 
    #    ||
        #   curl -s -F "token=$APP_TOKEN" \
        #   -F "user=$USER_KEY" \
        #   -F "title=$(uname -n) Says:" \
        #   # -F "device=s5"\
        #   -F "message=$1" https://api.pushover.net/1/messages.json
    #https://api.pushover.net/1/messages.json > /dev/null 2>&1
}

function push() {
    source $HOME/bin/email_variables.ínc
    curl -s -F "token=$APP_TOKEN" \
        -F "user=$USER_KEY" \
        -F "title=${TITLE:-No_Title}" \
        -F "message=$1" https://api.pushover.net/1/messages.json
}

###     Check so not to nest tmux sessions
#
#if [[ $TMUX ]]; then
#    source ~/.tmux-git/tmux-git.sh
#fi

sshtmux()
{
    # A name for the session
    local session_name="$(whoami)_sess"

    if [ ! -z $1 ]; then
        ssh -t "$1" "tmux attach -t $session_name || tmux new -s $session_name"
    else
        echo "Usage: sshtmux HOSTNAME"
        echo "You must specify a hostname"
    fi
}

###     Function for simple search and replace in current folder
#
function searchreplace() {
    echo -e "Search and replace for text in files: ${ORANGE} $PWD ${NC}\nSearch for:"
    read string_1
    echo -e "Replace ${yellow}$string_1 with:"
    read string_2
    find ./ -type f -exec sed -i 's/$string_1/$string_2/g' {} \;
}

###     Function for renaming parts of or whole filnem
#
function fnamereplace() {
    echo -e "Search and replace in filename in current ($PWD) folder\nSearch for:"
    read string_1
    echo -e "Replace ${yellow} $string_1 with:"
    read string_2
    find ./ -type -f exec rename 's/$string_1/$string_2/g' *
}

###     Function for dotfind (find folders with space in name
#
function dotfind(){
    find . -maxdepth 2 -type d -regex '.*/[^./][^/]*\.[^/]*'
}

function reverseempty(){
    if [ $# -ne 1 ]
    then
        echo "Usage : reverseempty <${ORANGE} music|movies|epub${NC} >"
        #exit 0 
    fi
    #source ~/bin/gits/bash-spinner/spinner.sh
    case $1 in
        music)
            echo -e "Searching for folders ${ORANGE}not${NC} containing ${GREEN} $1-files ${NC} in $PWD"
            #start_spinner 'searching...'
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a' _ {} \; -exec rm -rfv -- {} \;
            #stop_spinner $?
            ;;
        (movie|movies)
            echo -e "Searching for folders ${ORANGE}not${NC} containing ${GREEN} $1-files ${NC} in $PWD"
            #start_spinner 'searching...'
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.ogg" -o -iname "*.wmv" -o -iname "*m4v" \) -type f | read a' _ {} \; -exec rm -rfv -- {} \;
            #stop_spinner $?
            ;;
        epubs)
            echo -e "Searching for folders ${ORANGE}not${NC} containing ${GREEN} $1-files ${NC} in $PWD"
            #start_spinner 'searching...'
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a' _ {} \; -exec rm -rfv -- {} \;
            #stop_spinner $?
            ;;
        *)
            echo -e nothing choosen
            ;;
    esac
}

###     Help function - list all functions
#
function funchelp() {
    echo -e "Functions available:"
    typeset -f | awk '/ \(\) $/ && !/^main / {print $1}'
}


###     Lock folder
#
function lockfolder() {
    if ! [ $(id -u) = 0 ]; then
        echo "This command must run as root"
        exit 1
    else 
        touch .donotdelete
        chmod 444 .dotnotdelete
    fi
}

###     Clone all repos from user
#       (https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
function gh-clone-user() {
    [ -z "$1" ] && { echo "Usage: 'git clone <user>'" >&2; return; }
    curl -sL "https://api.github.com/users/$1/repos?per_page=1000" | jq -r '.[]|.clone_url' | xargs -L1 git clone --recurse-submodules
}

function gs_remove() {
    [ -z "$1" ] && { echo "Usage: 'jump to submodules folder in correct repo'" >&2; return; }
    git submodule deinit $1
    git rm $1
    git commit -m "Removed submodule $1"
    rm -rf $1
}


###     Automatically do an ls after each cd
function cd () {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
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
        fi
    fi
}

function setting_standard_commands() 
{
    case $OSSYS in
        solaris*)                                                           # Solaris
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            alias install="pkg install" $1
            alias {uninstall,remove}="pkg uninstall" $1
            alias app_search="pkg search" $1
            alias update="pkg update --accept"
            check_for_line
            os_status="solaris"
            ;;
        redhat*)                                                           #     YUM (RedHat Linux, centos)
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
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
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
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
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            #alias rm='rm -i' 
            # Upgrade
            alias apt_update="sudo aptitude update"
            # install
            alias install="apt install" $1
            alias {uninstall,remove}="sudo apt remove && sudo apt autoremove" $1
            alias {sys_update,update,sysupdate}="sudo sh -c 'apt update && apt upgrade -y && apt autoremove && apt autoremove'"
            alias {clean,sysclean}="sudo sh -c 'apt clean && apt autoremove && apt purge'"
            alias f_install="apt -f install" #force install
            alias reinstall="apt -f install --reinstall" # Force reinstall
            # Cleaning
            alias purge="apt purge"
            # alias deborphan="deborphan | xaargs sudo apt -y remove --purge"
            # Network Start, Stop, and Restart
            alias networkrestart="sudo service networking restart"
            alias networkstop="sudo service networking stop"
            alias networkstart="sudo service networking start"
            check_for_line
            os_status="Debian"
            ;;
        gentoo*)
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
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
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            check_for_line
            os_status="Mac/Darwin"
            ;; 
        *bsd) 
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
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
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
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
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
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
            #[[ $debug -eq 1 ]] && echo "Setting alias' for: ${DistroBasedOn^}" || echo "Setting alias' for: ${DistroBasedOn^}" >> $LOG; sleep ${SLEEP}
            check_for_line
            os_status="MS Windows"
            ;;
        *)        
            #[[ $debug -eq 1 ]] && echo "Unknown OS!" || echo "Unknown OS!" >> $LOG; sleep ${SLEEP} 
            check_for_line
            os_status="I have no clue"
            ;;
    esac
}

function check_for_line(){
        grep -E "#All your base are belong to ${DistroBasedOn^}" ~/.bashrc  >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo  "#All your base are belong to ${DistroBasedOn^}" >> ~/.bashrc
            #[[ $debug -eq 1 ]] && echo "$LOG_MESS_07_3" || echo "$LOG_MESS_07_3" >> ${LOG}; sleep ${SLEEP}
        else
            STATUS="Nothing was added to~/.bashrc!";  #echo $STATUS
        fi
}

# Usage
function usage(){
    cat <<EOF
 Usage: RunMe.sh [Options]
 Options:
   -h, --help: Show this message
EOF
}

function tail_me() {
    while :
    do
        tail -f $1; sleep 1
    done
}

###     Just to check if loaded
#
# echo ${file##*/}
###     Function for backing up latest command


#!/bin/ksh
