# -----------------------------------------------------------------------------
#
#   .bash_functions
#
# -----------------------------------------------------------------------------

# Source custom color & spinner scripts if available
[[ -f $HOME/bin/ColorCodes.inc ]]  && source $HOME/bin/ColorCodes.inc
[[ -f $HOME/bin/spinner.sh ]]      && source $HOME/bin/spinner.sh

function up() {
    ### Navigate Directory Upwards
    # If no argument, go up one directory
    # If numeric argument N, go up N directories
    # If string argument, go to parent directory named that string
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
    cd "$dir" || echo "Directory $dir does not exist"
}

function mcd() {
    ### Make Directory and cd into it
    if [ -z "$1" ]; then
        echo "Usage: mcd <directory name> (may need root if outside \$HOME)"
        return 1
    fi
    mkdir -p "$1" && cd "$1" || echo "Failed to create or enter directory"
}

function command_check() {
    ### Check if command or app exists
    command -v "$1" >/dev/null 2>&1
}

function startbitbucket() {
    ### Remote Bitbucket repo creation and git remote addition
    echo "Repo name?"
    read -r reponame
    username="b0red"
    password="AxREYw2WNEKj8YxTrRBt"
    curl --user "$username:$password" https://api.bitbucket.org/1.0/repositories/ --data name="$reponame" --data is_private='true'
    git remote add origin "git@bitbucket.org:$username/$reponame.git"
    git push -u origin --all
    git push -u origin --tags
}

function ff() {
    ### Find file recursively by exact name
    if [ -z "$1" ]; then
        echo "Usage: ff <filename>"
        return 1
    fi
    echo "Searching for $1"
    find . -name "$1"
}

function fif() {
    ### Find text recursively in files
    if [ -z "$1" ]; then
        echo "Usage: fif <text>"
        return 1
    fi
    echo "Searching for '$1' in $PWD"
    grep --exclude-dir={'.git','~/.ssh'} -Ril . -e "$1"
}

function hs() {
    ### Search shell history for command pattern
    if [ -z "$1" ]; then
        echo "Usage: hs <pattern>"
    else
        history | grep "$1"
    fi
}

function extract() {
    ### Extract archives (zip, tar, gz, bz2, rar, etc.)
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
                    echo "extract: '$archive' - unknown archive method"
                    return 1 ;;
            esac
        else
            echo "'$archive' does not exist"
            return 1
        fi
    done
}

function debug() {
    ### Debug wrapper to run bash with -x
    bash -x "$1"
}

function maketar() {
    ### Create tar.gz archive of a directory
    if [ $# -ne 1 ]; then
        echo "Usage: maketar <directory>"
        return 1
    fi
    tar -cvzf "${1%%/}.tar.gz" "${1%%/}/"
}

function makejar() {
    ### Create tar.bz2 archive of a directory
    if [ $# -ne 1 ]; then
        echo "Usage: makejar <directory>"
        return 1
    fi
    tar -cjf "${1%%/}.tar.bz2" "${1%%/}/"
}

function makezip() {
    ### Create ZIP archive of a directory or file
    if [ $# -ne 1 ]; then
        echo "Usage: makezip <directory_or_file>"
        return 1
    fi
    zip -r "${1}.zip" "$1"
}

function sssh() {
    ### ssh over tmux or screen session on remote host
    ssh -t "$1" 'tmux attach || tmux new || screen -DR'
}

function authme() {
    ### Copy SSH public key to remote server
    echo "Server?"
    read -r server
    ssh "$server" 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
}

function ltree() {
    ### Paginated colored tree output
    tree -C "$@" | less -R
}

function cdl() {
    ### cd and ls combined helper
    if [ -z "$1" ]; then
        echo "Usage: cdl <directory>"
        return 1
    fi
    cd "$1" && ls
}

function fstr() {
    ### Find and highlight a pattern in files
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

function mydf() {
    ### Pretty-print df output (inspired by dfc)
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

function ii() {
    ### Display detailed host info
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

function getnic() {
    ### Get active network interface
    nic=$(ip route | grep default | sed -e "s/^.*dev //" -e "s/ proto.*//")
    echo "NIC: $nic"
}

function myip() {
    ### Get IP address of active interface
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

function pushover() {
    ### Pushover function placeholder (non-working)
    echo "Function pushover is currently not working."
}

function push() {
    ### Pushover notification via curl
    source "$HOME/bin/email_variables.inc"
    curl -s -F "token=$APP_TOKEN" \
        -F "user=$USER_KEY" \
        -F "title=${TITLE:-No_Title}" \
        -F "message=$1" https://api.pushover.net/1/messages.json
}

function sshtmux() {
    ### SSH and tmux remote session connect
    local session_name
    session_name="$(whoami)_sess"
    if [ -n "$1" ]; then
        ssh -t "$1" "tmux attach -t $session_name || tmux new -s $session_name"
    else
        echo "Usage: sshtmux HOSTNAME"
        echo "You must specify a hostname"
    fi
}

function searchreplace() {
    ### Search and replace text in files in current folder
    echo -e "Search and replace in files in ${ORANGE}$PWD${NC}\nSearch for:"
    read -r string_1
    echo -e "Replace ${YELLOW}$string_1${NC} with:"
    read -r string_2
    find ./ -type f -exec sed -i "s/$string_1/$string_2/g" {} +
}

function fnamereplace() {
    ### Search and replace in filenames in current folder
    echo -e "Search and replace in filename in current ($PWD)\nSearch for:"
    read -r string_1
    echo -e "Replace ${YELLOW}$string_1${NC} with:"
    read -r string_2
    find ./ -type f -exec rename "s/$string_1/$string_2/g" {} +
}

function dotfind() {
    ### Find folders with dots in names up to depth 2
    find . -maxdepth 2 -type d -regex '.*/[^./][^/]*\.[^/]*'
}

function reverseempty() {
    ### Remove folders that do not contain certain media file types
    if [ $# -ne 1 ]; then
        echo "Usage : reverseempty <music|movies|epub>"
        return 1
    fi
    case "$1" in
        music)
            echo -e "Searching for folders ${ORANGE}NOT${NC} containing music files in $PWD"
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a' _ {} \;
            ;;
        movie|movies)
            echo -e "Searching for folders ${ORANGE}NOT${NC} containing movie files in $PWD"
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c 'find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.ogg" -o -iname "*.wmv" -o -iname "*.m4v" \) -type f | read a' _ {} \;
            ;;
        epubs|ePubs|epub)
            echo -e "Searching for folders ${ORANGE}NOT${NC} containing epub files in $PWD"
            find . -maxdepth 2 -mindepth 2 -type d \! -exec sh -c 'find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a' _ {} \;
            ;;
        *)
            echo "Nothing chosen or unknown category"
            return 1
            ;;
    esac
}

function funchelp() {
    ### List all functions available
    echo "Functions available:"
    typeset -f | awk '/ \(\) $/ && !/^main / {print $1}'
}

function lockfolder() {
    ### Lock folder by making a file readonly (runs as root)
    if [ "$(id -u)" -ne 0 ]; then
        echo "This command must run as root"
        return 1
    fi
    touch .donotdelete
    chmod 444 .donotdelete
}

function gh-clone-user() {
    ### Clone all public GitHub repos for a user
    if [ -z "$1" ]; then
        echo "Usage: gh-clone-user <github-username>"
        return 1
    fi
    curl -sL "https://api.github.com/users/$1/repos?per_page=1000" | jq -r '.[]|.clone_url' | xargs -L1 git clone --recurse-submodules
}

function gs_remove() {
    ### Remove git submodule safely
    if [ -z "$1" ]; then
        echo "Usage: gs_remove <submodule-path>"
        return 1
    fi
    git submodule deinit "$1"
    git rm "$1"
    git commit -m "Removed submodule $1"
    rm -rf "$1"
}

function cd() {
    ### Override cd to show ls after entering directory
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

function get_os() {
    ### OS detection function for alias setup (simplified)
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

function setting_standard_commands() {
    ### Set standard package manager aliases based on distro
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
            echo "Unknown OS base: $DISTRO_BASE"
            ;;
    esac
}

function functions() {
    ### get all function names or descriptions with -?
    if [[ "$1" == "-?" || "$1" == "--help" ]]; then
        echo "Available functions:"
        declare -F | awk '{print $3}' | while read -r fn; do
            # Get first comment line after function declaration for description
            desc=$(declare -f "$fn" | grep -m1 -E '^\s*#' | sed 's/^\s*#\s*//')
            printf "%-25s - %s\n" "$fn" "${desc:-No description}"
        done
    else
        # Without -? list all function names
        declare -F | awk '{print $3}'
    fi
}
