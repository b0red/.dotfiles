# -----------------------------------------------------------------------------
#   functions.bash
#   Custom bash functions for productivity and system management
# -----------------------------------------------------------------------------

# Source custom color & spinner scripts if available
[[ -f "$HOME/bin/ColorCodes.inc" ]] && source "$HOME/bin/ColorCodes.inc"
[[ -f "$HOME/bin/spinner.sh" ]] && source "$HOME/bin/spinner.sh"

function up() {
    ### Navigate directory upwards by level or name
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
    cd "$dir" || { echo "Directory $dir does not exist"; return 1; }
}

function mcd() {
    ### Make directory and cd into it
    if [ -z "$1" ]; then
        echo "Usage: mcd <directory_name>"
        return 1
    fi
    mkdir -p -- "$1" && cd -P -- "$1" || { echo "Failed to create or enter directory"; return 1; }
}

function command_check() {
    ### Check if command or app exists
    command -v "$1" >/dev/null 2>&1
}

function startbitbucket() {
    ### Create remote Bitbucket repo and add git remote
    # WARNING: Contains hardcoded credentials - consider using git credential helper
    echo "Repo name?"
    read -r reponame
    username="b0red"
    password="AxREYw2WNEKj8YxTrRBt"  # SECURITY RISK: Move to secure credential storage
    curl --user "$username:$password" https://api.bitbucket.org/1.0/repositories/ \
        --data name="$reponame" --data is_private='true'
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
    find . -type f -name "$1"
}

function fif() {
    ### Find text recursively in files
    if [ -z "$1" ]; then
        echo "Usage: fif <text>"
        return 1
    fi
    echo "Searching for '$1' in $PWD"
    grep --exclude-dir={'.git','.svn','node_modules'} -Ril "$1" .
}

function hs() {
    ### Search shell history for command pattern
    if [ -z "$1" ]; then
        echo "Usage: hs <pattern>"
        return 1
    fi
    history | grep "$1"
}

function extract() {
    ### Extract archives (zip, tar, gz, bz2, rar, etc)
    if [ -z "$1" ]; then
        cat <<'EOF'
Usage: extract <archive1> [archive2 ...]
Supported formats: zip, rar, bz2, gz, tar, tbz2, tgz, Z, 7z, xz, tar.bz2, tar.gz, tar.xz
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
                *.z|*.Z)
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
    if [ -z "$1" ]; then
        echo "Usage: debug <script.sh>"
        return 1
    fi
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
    tar -cjvf "${1%%/}.tar.bz2" "${1%%/}/"
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
    ### SSH and attach to tmux or screen session
    if [ -z "$1" ]; then
        echo "Usage: sssh <hostname>"
        return 1
    fi
    ssh -t "$1" 'tmux attach || tmux new || screen -DR'
}

function authme() {
    ### Copy SSH public key to remote server
    local server
    echo "Server?"
    read -r server
    if [ -z "$server" ]; then
        echo "No server specified"
        return 1
    fi
    # Check for modern key first, fallback to older formats
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        ssh "$server" 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
    elif [ -f ~/.ssh/id_rsa.pub ]; then
        ssh "$server" 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_rsa.pub
    elif [ -f ~/.ssh/id_dsa.pub ]; then
        ssh "$server" 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
    else
        echo "No SSH public key found in ~/.ssh/"
        return 1
    fi
    echo "Public key copied to $server"
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

function trim() {
    ### Trim leading and trailing whitespace from input
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

function paths() {
    ### Print the PATH variable nicely formatted
    echo "$PATH" | tr ':' '\n'
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

    find . -type f -name "${2:-*}" -print0 | \
        xargs -0 grep --color=always -sn ${mycase} "$1" 2>/dev/null | \
        less -R
}

function mydf() {
    ### Pretty-print df output with visual bar
    if [ -z "$1" ]; then
        echo "Usage: mydf <folder>"
        return 1
    fi
    for fs in "$@"; do
        if [ ! -d "$fs" ]; then
            echo "$fs : No such file or directory"
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
        echo "$out"
    done
}

function ii() {
    ### Display detailed host info
    echo -e "\nThis is ${ORANGE:-}$HOSTNAME${NC:-}"
    echo -e "\n${ORANGE:-}Additional information:${NC:-}" ; uname -a
    echo -e "\n${ORANGE:-}Users logged on:${NC:-}" ; w -hs | cut -d " " -f1 | sort | uniq
    echo -e "\n${ORANGE:-}Current date :${NC:-}" ; date
    echo -e "\n${ORANGE:-}Machine stats :${NC:-}" ; uptime
    echo -e "\n${ORANGE:-}Memory stats :${NC:-}" ; free -h
    echo -e "\n${ORANGE:-}Diskspace :${NC:-}" ; df -h / "$HOME" | tail -n +2
    echo -e "\n${ORANGE:-}Internal IP Address(es):${NC:-}"
    hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$' || \
        command ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1'
    echo -e "\n${ORANGE:-}External IP Address :${NC:-}"
    curl -4 -s ifconfig.me || curl -4 -s icanhazip.com || echo "Unable to retrieve external IP"
    echo -e "\n${ORANGE:-}Open connections :${NC:-}"
    ss -tunap 2>/dev/null || netstat -tunap 2>/dev/null || echo "Unable to retrieve connections (requires root/sudo)"
    echo
}

function getnic() {
    ### Get active network interface
    local nic
    # Try using command to bypass any alias
    nic=$(command ip route show default 2>/dev/null | awk '{print $5; exit}')
    
    if [ -z "$nic" ]; then
        nic=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0/ {print $NF; exit}')
    fi
    
    if [ -z "$nic" ]; then
        nic=$(route -n 2>/dev/null | awk '/^0.0.0.0/ {print $NF; exit}')
    fi
    
    if [ -z "$nic" ]; then
        nic=$(command ip addr 2>/dev/null | awk '/state UP/ {print $2}' | sed 's/:$//' | head -1)
    fi
    
    echo "${nic:-none}"
}

function myip() {
    ### Get IP address of active interface
    local nic ipaddr
    nic=$(getnic)
    if [ "$nic" = "none" ]; then
        echo "Not connected"
        return 1
    fi
    ipaddr=$(command ip addr show "$nic" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
    if [ -z "$ipaddr" ]; then
        echo "Not connected"
        return 1
    else
        echo "$ipaddr"
    fi
}

function pushover() {
    ### Pushover notification (requires configuration)
    echo "Function pushover is currently not configured."
    echo "Please set up email_variables.inc with APP_TOKEN and USER_KEY"
    return 1
}

function push() {
    ### Send Pushover notification via curl
    if [ ! -f "$HOME/bin/email_variables.inc" ]; then
        echo "Error: $HOME/bin/email_variables.inc not found"
        return 1
    fi
    source "$HOME/bin/email_variables.inc"
    
    if [ -z "$APP_TOKEN" ] || [ -z "$USER_KEY" ]; then
        echo "Error: APP_TOKEN or USER_KEY not set in email_variables.inc"
        return 1
    fi
    
    if [ -z "$1" ]; then
        echo "Usage: push <message> [title]"
        return 1
    fi
    
    curl -s -F "token=$APP_TOKEN" \
        -F "user=$USER_KEY" \
        -F "title=${2:-${TITLE:-Notification}}" \
        -F "message=$1" https://api.pushover.net/1/messages.json
}

function sshtmux() {
    ### SSH and attach to named tmux session
    local session_name
    session_name="$(whoami)_sess"
    if [ -z "$1" ]; then
        echo "Usage: sshtmux <hostname>"
        return 1
    fi
    ssh -t "$1" "tmux attach -t $session_name || tmux new -s $session_name"
}

function searchreplace() {
    ### Search and replace text in files in current folder
    echo -e "Search and replace in files in ${ORANGE:-}$PWD${NC:-}\nSearch for:"
    read -r string_1
    if [ -z "$string_1" ]; then
        echo "No search string provided"
        return 1
    fi
    echo -e "Replace ${YELLOW:-}$string_1${NC:-} with:"
    read -r string_2
    
    echo "This will modify files in $PWD. Continue? (y/n)"
    read -r confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Cancelled"
        return 1
    fi
    
    find . -type f -exec sed -i "s/$string_1/$string_2/g" {} +
    echo "Replacement complete"
}

function fnamereplace() {
    ### Search and replace in filenames in current folder
    echo -e "Search and replace in filenames in ${ORANGE:-}$PWD${NC:-}\nSearch for:"
    read -r string_1
    if [ -z "$string_1" ]; then
        echo "No search string provided"
        return 1
    fi
    echo -e "Replace ${YELLOW:-}$string_1${NC:-} with:"
    read -r string_2
    
    # Check if rename command exists
    if ! command -v rename >/dev/null 2>&1; then
        echo "Error: 'rename' command not found. Install perl-rename package."
        return 1
    fi
    
    echo "This will rename files in $PWD. Continue? (y/n)"
    read -r confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Cancelled"
        return 1
    fi
    
    find . -type f -exec rename "s/$string_1/$string_2/g" {} +
    echo "Renaming complete"
}

function dotfind() {
    ### Find folders with dots in names up to depth 2
    find . -maxdepth 2 -type d -regex '.*/[^./][^/]*\.[^/]*'
}

function reverseempty() {
    ### Find folders not containing certain media file types
    if [ $# -ne 1 ]; then
        echo "Usage: reverseempty <music|movies|epub>"
        return 1
    fi
    case "$1" in
        music)
            echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing music files in $PWD"
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c \
                'find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a' _ {} \; -print
            ;;
        movie|movies)
            echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing movie files in $PWD"
            find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c \
                'find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.mp4" -o -iname "*.wmv" -o -iname "*.m4v" \) -type f | read a' _ {} \; -print
            ;;
        epubs|ePubs|epub)
            echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing epub files in $PWD"
            find . -maxdepth 2 -mindepth 2 -type d \! -exec sh -c \
                'find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a' _ {} \; -print
            ;;
        *)
            echo "Unknown category: $1"
            echo "Usage: reverseempty <music|movies|epub>"
            return 1
            ;;
    esac
}

function funchelp() {
    ### List all custom functions available
    echo "Custom functions available:"
    typeset -f | awk '/ \(\) $/ && !/^main / {print $1}' | grep -v '^_'
}

function lockfolder() {
    ### Lock folder by making a marker file readonly
    if [ "$(id -u)" -ne 0 ]; then
        echo "This command must run as root"
        return 1
    fi
    touch .donotdelete
    chmod 444 .donotdelete
    echo "Folder locked with .donotdelete marker"
}

function gh-clone-user() {
    ### Clone all public GitHub repos for a user
    if [ -z "$1" ]; then
        echo "Usage: gh-clone-user <github-username>"
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed"
        return 1
    fi
    
    curl -sL "https://api.github.com/users/$1/repos?per_page=1000" | \
        jq -r '.[]|.clone_url' | \
        xargs -L1 git clone --recurse-submodules
}

function gs_remove() {
    ### Remove git submodule safely
    if [ -z "$1" ]; then
        echo "Usage: gs_remove <submodule-path>"
        return 1
    fi
    
    if [ ! -f .gitmodules ]; then
        echo "Error: Not in a git repository with submodules"
        return 1
    fi
    
    git submodule deinit -f "$1"
    git rm -f "$1"
    git commit -m "Removed submodule $1"
    rm -rf ".git/modules/$1"
    echo "Submodule $1 removed"
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
    ### Detect OS and distribution information
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    KERNEL=$(uname -r)
    MACH=$(uname -m)
    DISTRO="unknown"
    DISTRO_BASE="unknown"
    
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_BASE="${ID_LIKE:-$DISTRO}"
    elif [ -f /etc/lsb-release ]; then
        source /etc/lsb-release
        DISTRO="${DISTRIB_ID:-unknown}"
        DISTRO_BASE="$DISTRO"
    fi
    
    export OS KERNEL MACH DISTRO DISTRO_BASE
    
    # Display the values
    echo "OS: $OS"
    echo "KERNEL: $KERNEL"
    echo "MACH: $MACH"
    echo "DISTRO: $DISTRO"
    echo "DISTRO_BASE: $DISTRO_BASE"
}

function setting_standard_commands() {
    ### Set package manager aliases based on distribution
    # Get OS info if not already set
    if [ -z "$DISTRO_BASE" ]; then
        get_os >/dev/null
    fi
    
    case "$DISTRO_BASE" in
        debian*|ubuntu*)
            alias install="sudo apt-get install -y"
            alias uninstall="sudo apt-get remove -y"
            alias update="sudo apt-get update && sudo apt-get upgrade -y"
            ;;
        rhel*|redhat*|centos*|fedora*)
            if command -v dnf >/dev/null 2>&1; then
                alias install="sudo dnf install -y"
                alias uninstall="sudo dnf remove -y"
                alias update="sudo dnf update -y"
            else
                alias install="sudo yum install -y"
                alias uninstall="sudo yum remove -y"
                alias update="sudo yum update -y"
            fi
            ;;
        arch*)
            alias install="sudo pacman -Syu --noconfirm"
            alias uninstall="sudo pacman -Rns --noconfirm"
            alias update="sudo pacman -Syu --noconfirm"
            ;;
        gentoo*)
            alias install="sudo emerge"
            alias uninstall="sudo emerge --unmerge"
            alias update="sudo emerge --update --deep --newuse @world"
            ;;
        *)
            echo "Unknown OS base: $DISTRO_BASE"
            return 1
            ;;
    esac
    echo "Package manager aliases set for $DISTRO_BASE"
}

function functions() {
    ### List function names or descriptions with -?
    local func_file="$HOME/dotfiles/.bashrc.d/functions.bash"
    
    if [[ "$1" == "-?" || "$1" == "--help" ]]; then
        echo "Available functions:"
        if [ -f "$func_file" ]; then
            awk '/^function [a-zA-Z_][a-zA-Z0-9_]*\(\)/ {
                fname = $2
                gsub(/\(\).*/, "", fname)
                getline
                if ($0 ~ /###/) {
                    sub(/.*###[[:space:]]*/, "")
                    printf "  %-30s %s\n", fname, $0
                }
            }' "$func_file"
        else
            echo "Could not find function source file: $func_file"
            return 1
        fi
    else
        # List function names, excluding system functions
        declare -F | awk '{print $3}' | sed 's/^[0-9]*://' | grep -v '^_' | column -c 80
    fi
}