# -----------------------------------------------------------------------------
#
#   .bash_functions
#
# -----------------------------------------------------------------------------

### Define & source colors and spinner for pretty output and long command spinners
[[ -f "$HOME/bin/ColorCodes.inc" ]]  && source "$HOME/bin/ColorCodes.inc"          # For pretty colored output
[[ -f "$HOME/bin/spinner.sh" ]]     && source "$HOME/bin/spinner.sh"              # Spinner for long running commands


### Go up directories conveniently:
# - No argument: up one directory
# - Numeric argument: go up that many directories
# - String argument: go to parent directory with that name
function up() {
    local dir=""
    if [ -z "$1" ]; then
        dir=".."
    elif [[ $1 =~ ^[0-9]+$ ]]; then
        local x=0
        dir=""
        while [ "$x" -lt "$1" ]; do
            dir="${dir}../"
            x=$((x+1))
        done
    else
        dir="${PWD%/$1/*}/$1"
    fi
    cd "$dir" || echo "Directory $dir not found"
}

### Make directory and enter it
function mcd() {
    if [ -z "$1" ]; then
        echo "Usage: mcd <directory name> (Need to be root if outside of \$HOME)"
        return 1
    fi
    mkdir -p "$1" && cd "$1" || echo "Failed to create or enter directory"
}

### Check if a command exists in PATH
function command_check() {
    command -v "$1" >/dev/null 2>&1
}

### Create a remote repo on Bitbucket and add it as a git remote to current directory
function startbitbucket() {
    echo "Repo name?"
    read -r reponame
    local username="b0red"
    local password="AxREYw2WNEKj8YxTrRBt"
    curl --user "$username:$password" https://api.bitbucket.org/1.0/repositories/ --data name="$reponame" --data is_private='true'
    git remote add origin "git@bitbucket.org:$username/$reponame.git"
    git push -u origin --all
    git push -u origin --tags
}

### Find file by exact name recursively
function ff() {
    if [ -z "$1" ]; then
        echo "Usage: ff <filename to search for>"
        return 1
    fi
    echo "Searching for: $1"
    find . -name "$1"
}

### Search text recursively in files
function fif() {
    if [ -z "$1" ]; then
        echo "Usage: fif <text> - search text recursively from $PWD"
        return 1
    fi
    echo "Searching for '$1' in $PWD"
    grep --exclude-dir={'.git','~/.ssh'} -Ril . -e "$1"
}

### Search command in bash history
function hs() {
    if [ -z "$1" ]; then
        echo "Usage: hs <command to search for>"
    else
        history | grep "$1"
    fi
}

### Extract common archive formats
function extract() {
    if [ -z "$1" ]; then
        cat <<EOF
Usage: extract <archive1> [archive2 ...]
Supported formats: zip, rar, bz2, gz, tar, tbz2, tgz, Z, 7z, xz, ex, tar.bz2, tar.gz, tar.xz
EOF
        return 1
    fi

    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case "$archive" in
                *.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                    tar xvf "$archive" ;;
                *.lzma)
                    unlzma "$archive" ;;
                *.bz2)
                    bunzip2 "$archive" ;;
                *.rar)
                    unrar x -ad "$archive" ;;
                *.gz)
                    gunzip "$archive" ;;
                *.zip)
                    unzip "$archive" ;;
                *.z)
                    uncompress "$archive" ;;
                *.7z|*.arj|*.cab|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.rpm|*.udf|*.wim|*.xar)
                    7z x "$archive" ;;
                *.xz)
                    unxz "$archive" ;;
                *.exe)
                    cabextract "$archive" ;;
                *)
                    echo "extract: '$archive' - unknown archive method"; return 1 ;;
            esac
        else
            echo "'$archive' - file does not exist"
            return 1
        fi
    done
}

### Debug wrap: run bash -x on a script
function debug() {
    bash -x "$1"
}

### Create a gzipped tar archive of a directory
function maketar() {
    if [ $# -ne 1 ]; then
        echo "Usage: maketar <directory>"
        return 1
    fi
    tar -cvzf "${1%%/}.tar.gz" "${1%%/}/"
}

### Create a bzipped tar archive of a directory
function makejar() {
    if [ $# -ne 1 ]; then
        echo "Usage: makejar <directory>"
        return 1
    fi
    tar -cjf "${1%%/}.tar.bz2" "${1%%/}/"
}

### Create a ZIP archive of a directory or file
function makezip() {
    if [ $# -ne 1 ]; then
        echo "Usage: makezip <directory_or_file>"
        return 1
    fi
    zip -r "${1}.zip" "$1"
}

### Connect or attach to tmux or screen session over ssh
function sssh() {
    ssh -t "$1" 'tmux attach || tmux new || screen -DR'
}

### Copy public SSH key to remote server
function authme() {
    echo "Server?"
    read -r server
    ssh "$server" 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
}

### Paginated colored tree listing
function ltree() {
    tree -C "$@" | less -R
}

### Change directory and list files
function cdl() {
    if [ -z "$1" ]; then
        echo "Usage: cdl <directory>"
        return 1
    fi
    cd "$1" && ls
}

### Find pattern in files and highlight
function fstr() {
    local mycase=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"]"

    OPTIND=1
    while getopts :i opt; do
        case "$opt" in
            i) mycase="-i " ;;
            *) echo "$usage"; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return 1
    fi

    find . -type f -name "${2:-*}" -print0 | xargs -0 egrep --color=always -sn ${mycase} "$1" 2>/dev/null | less
}

### Pretty-print df output similar to dfc utility
function mydf() {
    if [ -z "$1" ]; then
        echo "Usage: mydf <folder>"
        return 1
    fi
    for fs in "$@"; do
        if [ ! -d "$fs" ]; then
            echo -e "$fs : No such file or directory"
            continue
        fi
        local info=( $(df -P "$fs" | awk 'END{ print $2,$3,$5 }') )
        local free=( $(df -Pkh "$fs" | awk 'END{ print $4 }') )
        local nbstars=$(( 20 * ${info[1]} / ${info[0]} ))
        local out="["
        for ((j=0;j<20;j++)); do
            if [ $j -lt $nbstars ]; then out+="*"; else out+="-"; fi
        done
        out+=${info[2]}" ] ("${free[0]}" free on $fs)"
        echo -e "$out"
    done
}

### Display detailed host information
function ii() {
    echo -e "\nThis is ${ORANGE}$HOSTNAME${NC}"
    echo -e "\n${ORANGE}Additional information:${NC}" ; uname -a
    echo -e "\n${ORANGE}Users logged on:${NC}" ; w -hs | cut -d " " -f1 | sort | uniq
    echo -e "\n${ORANGE}Current date :${NC}" ; date
    echo -e "\n${ORANGE}Machine stats :${NC}" ; uptime
    echo -e "\n${ORANGE}Memory stats :${NC}" ; free -h
    echo -e "\n${ORANGE}Diskspace :${NC}" ; mydf / "$HOME"
    echo -e "\n${ORANGE}Local IP Address :${NC}" ; myip
    echo -e "\n${ORANGE}Open connections :${NC}" ; netstat -pan --inet
    echo
}

### Get active Network Interface
function getnic() {
    nic=$(ip route | grep default | sed -e "s/^.*dev //" -e "s/ proto.*//")
    echo "NIC: $nic"
}

### Get IP address on active interface
function myip() {
    local nic
    nic=$(getnic)
    local ipaddr
    ipaddr=$(ip addr show "$nic" | awk '/inet / {print $2}' | cut -d/ -f1)
    if [ -z "$ipaddr" ]; then
        echo "Not connected"
    else
        echo "$ipaddr"
    fi
}

### Function to send pushover notifications (currently broken)
function pushover() {
    echo "Function pushover is currently not working."
}

### Function to send pushover notifications using curl
function push() {
    source "$HOME/bin/email_variables.inc"
    curl -s -F "token=$APP_TOKEN" \
        -F "user=$USER_KEY" \
        -F "title=${TITLE:-No_Title}" \
        -F "message=$1" https://api.pushover.net/1/messages.json
}

### SSH TMUX session connect function - attach or create tmux session remotely
function sshtmux() {
    local session_name
    session_name="$(whoami)_sess"
    if [ -n "$1" ]; then
        ssh -t "$1" "tmux attach -t $session_name || tmux new -s $session_name"
    else
        echo "Usage: sshtmux HOSTNAME"
        echo "You must specify a hostname"
    fi
}

### Simple search and replace in current folder files
function searchreplace() {
    echo -e "Search and replace for text in files in ${ORANGE}$PWD${NC}\nSearch for:"
    read -r string_1
    echo -e "Replace ${YELLOW}$string_1${NC} with:"
    read -r string_2
    find ./ -type f -exec sed -i "s/$string_1/$string_2/g" {} +
}

### Function for renaming parts of or whole filename
function fnamereplace() {
    echo -e "Search and replace in filename in current ($PWD) folder\nSearch for:"
    read -r string_1
    echo -e "Replace ${YELLOW}$string_1${NC} with:"
    read -r string_2
    find ./ -type f -exec rename "s/$string_1/$string_2/g" {} +
}

### Find folders with dot in their name only up to depth 2
function dotfind() {
    find . -maxdepth 2 -type d -regex '.*/[^./][^/]*\.[^/]*'
}

### Search for folders not containing specified media files and optionally remove
function reverseempty() {
    if [ $# -ne 1 ]; then
        echo "Usage : reverseempty <music|movies|epub>"
        return 1
    fi
    case "$1" in
        music)
            echo -e "Searching for folders ${ORANGE}NOT${NC} containing ${GREEN}$1-files${NC} in $PWD"
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a' _ {} \;
            ;;
        movie|movies)
            echo -e "Searching for folders ${ORANGE}NOT${NC} containing ${GREEN}$1-files${NC} in $PWD"
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.ogg" -o -iname "*.wmv" -o -iname "*.m4v" \) -type f | read a' _ {} \;
            ;;
        epubs|ePubs|epub)
            echo -e "Searching for folders ${ORANGE}NOT${NC} containing ${GREEN}$1-files${NC} in $PWD"
            find . -maxdepth 2 -mindepth 2 -type d \! -exec sh -c 'find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a' _ {} \;
            ;;
        *)
            echo "Nothing chosen or unknown category"
            return 1
            ;;
    esac
}

### List loaded functions
function funchelp() {
    echo "Functions available:"
    typeset -f | awk '/ \(\) $/ && !/^main / {print $1}'
}

### Lock folder by creating a readonly marker (root only)
function lockfolder() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This command must run as root"
        return 1
    fi
    touch .donotdelete
    chmod 444 .donotdelete
}

### Clone all repos from GitHub user
function gh-clone-user() {
    if [ -z "$1" ]; then
        echo "Usage: gh-clone-user <github-user>"
        return 1
    fi
    curl -sL "https://api.github.com/users/$1/repos?per_page=1000" | jq -r '.[]|.clone_url' | xargs -L1 git clone --recurse-submodules
}

### Remove git submodule safely
function gs_remove() {
    if [ -z "$1" ]; then
        echo "Usage: gs_remove <submodule-path>"
        return 1
    fi
    git submodule deinit "$1"
    git rm "$1"
    git commit -m "Removed submodule $1"
    rm -rf "$1"
}

### Override cd command to list contents after changing directory
function cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

### Detect OS type and variants, setting global variables for use in other scripts
function get_os() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    KERNEL=$(uname -r)
    MACH=$(uname -m)
    DISTRO="unknown"
    DISTRO_BASE="unknown"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_BASE="${ID_LIKE:-$DISTRO}"
    fi

    export OS KERNEL MACH DISTRO DISTRO_BASE
}

### Set standard package manager command aliases based on OS type
function setting_standard_commands() {
    case "$DISTRO_BASE" in
        debian*|ubuntu*)
            alias install="sudo apt-get install -y"
            alias uninstall="sudo apt-get remove -y"
            alias update="sudo apt-get update && sudo apt-get upgrade -y"
            ;;
        redhat*|centos*|fedora*)
            alias install="sudo yum install -y"
            alias uninstall="sudo yum remove -y"
            alias update="sudo yum update -y"
            ;;
        arch*)
            alias install="sudo pacman -Syu --noconfirm"
            alias uninstall="sudo pacman -Rns --noconfirm"
            alias update="sudo pacman -Syu --noconfirm"
            ;;
        gentoo*)
            alias install="sudo emerge"
            alias uninstall="sudo emerge --unmerge"
            alias update="sudo emerge --update --deep @world"
            ;;
        *)
            echo "Unknown or unsupported OS base: $DISTRO_BASE"
            ;;
    esac
}
