# ---------------------------------------------------------------------------------
#
#	.bash_functions
#
# ---------------------------------------------------------------------------------
#

###	Create dir and enter it
#
mcd () {
    mkdir -p -- "$1" &&
    cd -p -- "$1"
}

###	Startbitbucket - creates remote bitbucket repo and adds it as git remote to cwd
#
function startbitbucket () {
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

###	Find files/dirs by name recursively.
#
# Usage: ff (file)
#f() {
#  find . -name "*$1*"
#}

###	Find file by exact name recursively.
#
# Usage: ff (file)
ff() {
    find . -name "$1"
}

# Allows you to search for any text in any file recursively.
# Usage: ft "my string" *.php
fif() {
    find . -name "$2" -exec grep -il "$1" {} \;
}

# Search for command in history.
# Usage: hs (string)
hs() {
    history | grep "$1"
}

###	Extract most know archives
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

###	Debug
#
function debug() {
    bash -x "$1"
}


###	Creates an archive (*.tar.gz) from given directory.
#
function maketar() {
    tar cvzf "${1%%/}.tar.gz"  "${1%%/}/";
}

###	Create a ZIP archive of a file or folder.
#
function makezip() {
    zip -r "${1%%/}.zip" "$1" ;
}

###	Reconnect or start a tmux or screen session over ssh
#
function sssh () {
    ssh -t "$1" 'tmux attach || tmux new || screen -DR';
}

###	Copy public key to remote machine (dependency-less)
#
function authme() {
    echo Server?
    read server
    # ssh "$1" 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
    ssh $server 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
}

###	Paginated colored tree
#
function ltree() {
    tree -C $* | less -R
}

###	CD and ls a directory
#
function cdl () {
    cd $1; ls
}

###	Find a pattern in a set of files and highlight them:
#	+ (needs a recent version of egrep).
#
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


###	Pretty-print of 'df' output.
#	Inspired by 'dfc' utility.
#
function mydf() {
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
}


###	Get current host related info.
#
function ii() {
    echo -e "\nYou are logged on ${BRed}$HOST"
    echo -e "\n${BRed}Additionnal information:$NC " ; uname -a
    echo -e "\n${BRed}Users logged on:$NC " ; w -hs |
    cut -d " " -f1 | sort | uniq
    echo -e "\n${BRed}Current date :$NC " ; date
    echo -e "\n${BRed}Machine stats :$NC " ; uptime
    echo -e "\n${BRed}Memory stats :$NC " ; free
    echo -e "\n${BRed}Diskspace :$NC " ; mydf / $HOME
    echo -e "\n${BRed}Local IP Address :$NC" ; my_ip
    echo -e "\n${BRed}Open connections :$NC "; netstat -pan --inet;
    echo
}

###	Get IP adress on ethernet.
#
function myip() {
    MY_IP=$(/sbin/ifconfig eth0 | awk '/inet/ { print $2 } ' | sed -e s/addr://)
    echo ${MY_IP:-"Not connected"}
}

###	Send pushover messages
#
function pushover() {
    $include $HOME/bin/email_varibles.cfg
    curl -s -F "token=$APP_TOKEN" \
    -F "user=$USER_KEY" \
    -F "title=$(uname -n) Says:" \
    # -F "device=s5"\
    -F "message=$1" https://api.pushover.net/1/messages.json
    https://api.pushover.net/1/messages.json > /dev/null 2>&1
}
alias comstat="push \"Kommandot kört! (uname -n)\" || push \"Kommandot misslyckades!\""

###     Check so not to nest tmux sessions
if [[ $TMUX ]]; then
    source ~/.tmux-git/tmux-git.sh
fi

### echo ".bash_functions loaded"

###     Just to check if loaded
#
# echo ${file##*/}
