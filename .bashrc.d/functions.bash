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

###	    Create dir and enter it
#
function mcd () { # Makes a directory and enters it
    [ -z "$1" ] && { echo "Usage: 'mcd <directory name> (Need to be root if outside of $HOME)'" >&2; return; }
        mkdir -p "$1" && 
        cd "$1"
}

###	    Startbitbucket - creates remote bitbucket repo and adds it as git remote to cwd
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

###	    Find file by exact name recursively.
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
        echo "Usage: Enter 'fif <text>' to search for in files recursevly from <location>. Default is: $PWD"
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
    tar cvzf "${1%%/}.tar.gz"  "${1%%/}/";
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
    # ssh "$1" 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
    ssh $server 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
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
#	      + (needs a recent version of egrep).
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
    MY_IP=$(/sbin/ifconfig $(getnic) | awk '/inet/ { print $2 } ' | sed -e s/addr://)
    echo ${MY_IP:-"Not connected"}
}

###     Get active Network Interface
#
function getnic() { 
    nic=$(sudo ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
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
if [[ $TMUX ]]; then
    source ~/.tmux-git/tmux-git.sh
fi

###     Check if command exists
#
#function command_exists() {
#    command -v "$1" &> /dev/null 
#}

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
    source ~/bin/gits/bash-spinner/spinner.sh
    case $1 in
        music)
            echo -e "Searching for folders ${ORANGE}not${NC} containing ${GREEN} $1-files ${NC} in $PWD"
            start_spinner 'searching...'
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a' _ {} \; -exec rm -rfv -- {} \;
            stop_spinner $?
            ;;
        (movie|movies)
            echo -e "Searching for folders ${ORANGE}not${NC} containing ${GREEN} $1-files ${NC} in $PWD"
            start_spinner 'searching...'
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.ogg" -o -iname "*.wmv" -o -iname "*m4v" \) -type f | read a' _ {} \; -exec rm -rfv -- {} \;
            stop_spinner $?
            ;;
        epubs)
            echo -e "Searching for folders ${ORANGE}not${NC} containing ${GREEN} $1-files ${NC} in $PWD"
            start_spinner 'searching...'
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a' _ {} \; -exec rm -rfv -- {} \;
            stop_spinner $?
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
#           (https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
function gh-clone-user() {
    [ -z "$1" ] && { echo "Usage: 'git clone <user>'" >&2; return; }
    curl -sL "https://api.github.com/users/$1/repos?per_page=1000" | jq -r '.[]|.clone_url' | xargs -L1 git clone --recurse-submodules
}



### Function to backup latest commands
#
#function backup() { 
#    local CA=c T=/backup.tar.gz; [[ -f  ]]&& C=r; find ~ -type f -newer  | tar vfz  -T - ;
#}

###     Just to check if loaded
#
# echo ${file##*/}
###     Function for backing up latest command






