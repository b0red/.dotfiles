# shellcheck shell=bash
# shellcheck disable=SC1090

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

function ff() {
    ### Find file recursively by exact name
    if [ -z "$1" ]; then
        echo "Usage: ff <filename>"
        return 1
    fi
    echo "Searching for $1"
    find . -type f -name "$1"
}

function quickscan() {
    ### Quick port scan of common ports on target (default: localhost)
    local target=${1:-127.0.0.1}
    # A small sample of common ports (SSH, HTTP, HTTPS, DBs, etc.)
    local ports=(21 22 23 25 53 80 110 139 143 443 445 1433 1521 3306 3389 5432 8080 8443)
    
    echo "Quick scanning $target for common services..."
    
    for port in "${ports[@]}"; do
        (
            if (echo < /dev/tcp/"$target"/"$port") &>/dev/null; then
                printf "[+] Found service on port: %d\n" "$port"
            fi
        ) &
    done
    wait
    echo "Quick scan finished."
}

function fif() {
    ### Find text recursively in files (rg preferred, grep fallback)
    # Supports file or directory targets
    # Ignore rules configurable via env vars

    local search=""
    local target="."
    local ignore_case=false
    local show_lines=false
    local backend="grep"
    local OPTIND opt

    # Defaults (can be overridden via env)
    local ignore_dirs="${FIF_IGNORE_DIRS:-.git,.svn,node_modules}"
    local ignore_files="${FIF_IGNORE_FILES:-}"

    # Detect backend
    if command -v rg >/dev/null 2>&1; then
        backend="rg"
    fi

    # Help / short description
    if [[ "$1" == "-?" || $# -eq 0 ]]; then
        echo "fif — recursively find text in files"
        echo
        echo "Usage:"
        echo "  fif <text> [path|file]"
        echo "  fif [-i] [-n] <text> [path|file]"
        echo
        echo "Options:"
        echo "  -i    case-insensitive search"
        echo "  -n    show matching lines with line numbers"
        echo "  -?    show this help"
        echo
        echo "Environment:"
        echo "  FIF_IGNORE_DIRS   comma-separated dir names"
        echo "  FIF_IGNORE_FILES  comma-separated file globs"
        echo
        echo "Backend:"
        echo "  Using: $backend"
        return 0
    fi

    # Parse options
    while getopts ":in?" opt; do
        case "$opt" in
            i) ignore_case=true ;;
            n) show_lines=true ;;
            ?) fif -?; return 0 ;;
            *)
                echo "Unknown option: -$OPTARG"
                return 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    search=$1
    [[ -n "$2" ]] && target="$2"

    # Expand ~ safely
    target="${target/#\~/$HOME}"

    # Validate search
    if [[ -z "$search" ]]; then
        echo "Error: search text is required"
        return 1
    fi

    # Validate target
    if [[ ! -e "$target" ]]; then
        echo "Error: '$target' does not exist"
        return 1
    fi

    # Normalize file target → directory
    if [[ -f "$target" ]]; then
        target=$(dirname "$target")
    fi

    # Split ignore lists into arrays
    local IFS=',' 
    read -r -a ignore_dir_arr <<< "$ignore_dirs"
    read -r -a ignore_file_arr <<< "$ignore_files"

    if [[ "$backend" == "rg" ]]; then
        # -------------------
        # ripgrep path
        # -------------------
        local rg_opts=(
            "--color=auto"
            "--hidden"
        )

        $ignore_case && rg_opts+=("-i")
        $show_lines || rg_opts+=("-l")

        # Disable colors if piped
        [[ -t 1 ]] || rg_opts+=("--color=never")

        for d in "${ignore_dir_arr[@]}"; do
            [[ -n "$d" ]] && rg_opts+=("--glob" "!**/$d/**")
        done

        for f in "${ignore_file_arr[@]}"; do
            [[ -n "$f" ]] && rg_opts+=("--glob" "!$f")
        done

        rg "${rg_opts[@]}" -- "$search" "$target"

    else
        # -------------------
        # grep fallback
        # -------------------
        local grep_opts=("-R" "--color=auto")

        $ignore_case && grep_opts+=("-i")
        if $show_lines; then
            grep_opts+=("-n")
        else
            grep_opts+=("-l")
        fi

        for d in "${ignore_dir_arr[@]}"; do
            [[ -n "$d" ]] && grep_opts+=("--exclude-dir=$d")
        done

        for f in "${ignore_file_arr[@]}"; do
            [[ -n "$f" ]] && grep_opts+=("--exclude=$f")
        done

        grep "${grep_opts[@]}" -- "$search" "$target"
    fi
}

function hs() {
    ### Search bash history for command pattern
    if [[ -z $1 || $1 == "-?" ]]; then
        echo "hs <pattern>"
        return 0
    fi
    history | grep -- "$1"
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
    ### List tree of directory with default ignores, paged
    # Usage:
    #   ltree                # tree of $PWD, show dotfiles
    #   ltree src            # tree of src
    #   ltree -I '.git|.gitignore|.git*'  # custom ignore
    #
    # Default ignore pattern (override via LTreeIgnore or -I)
    local default_ignore='.git|.git*'

    # If no -I provided in args, add default (unless env overrides)
    local have_I=false
    for arg in "$@"; do
        if [[ "$arg" == "-I" ]]; then
            have_I=true
            break
        fi
    done

    # Build args: always color (-C), show dotfiles (-a)
    local args=(-a -C -F -A --dirsfirst)

    # Inject ignore pattern if none given
    if ! $have_I; then
        local pattern="${LTreeIgnore:-$default_ignore}"
        args+=(-I "$pattern")
    fi

    # If no directory/file arguments and no explicit path-like arg, use "."
    if [[ $# -eq 0 ]]; then
        args+=(".")
    else
        args+=("$@")
    fi

    # Call real tree (bypass alias) and page output
    command tree "${args[@]}" | less -R
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
    if [[ $# -eq 0 ]]; then
        echo "Usage: mydf <folder> [folder2 ...]"
        return 1
    fi

    for fs in "$@"; do
        if [[ ! -d "$fs" ]]; then
            echo "$fs : No such file or directory"
            continue
        fi

        # df --block-size=1 gives raw bytes (pure numbers)
        # Fields: Filesystem Size Used Avail Use% Mounted_on
        local df_line
        df_line=$(df --block-size=1 "$fs" | awk 'NR==2 {print $2, $3, $5}')

        read -r total used pct <<< "$df_line"

        # Human-readable free space
        free=$(df -Ph "$fs" | awk 'NR==2 {print $4}')

        # Sanity check
        if [[ -z "$total" || -z "$used" || ! "$total" =~ ^[0-9]+$ || "$total" -eq 0 ]]; then
            echo "Cannot compute usage for $fs (bad df output)"
            continue
        fi

        # Compute stars (0-20)
        local nbstars=$((20 * used / total))

        # Build bar
        local bar="["
        for ((j = 0; j < 20; j++)); do
            if ((j < nbstars)); then
                bar+="*"
            else
                bar+="-"
            fi
        done
        bar+="]"

        echo "$bar $pct ( $free free on $fs )"
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
    ### Search and replace text in files recursively (safe)
    if [[ $# -lt 2 || $1 == "-?" ]]; then
        echo "searchreplace <search> <replace> [path]"
        return 0
    fi

    local search replace path
    search=$1
    replace=$2
    path=${3:-.}

    # Escape for sed
    local esc_search esc_replace
    esc_search=$(printf '%s' "$search" | sed 's/[\/&]/\\&/g')
    esc_replace=$(printf '%s' "$replace" | sed 's/[\/&]/\\&/g')

    grep -rl -- "$search" "$path" | while IFS= read -r file; do
        sed -i "s/$esc_search/$esc_replace/g" "$file"
    done
    echo "Replacement complete"
}

function fnamereplace() {
    ### Replace text in filenames safely
    if [[ $# -lt 2 || $1 == "-?" ]]; then
        echo "fnamereplace <search> <replace> [path]"
        return 0
    fi

    local search=$1
    local replace=$2
    local path=${3:-.}

    find "$path" -depth -name "*$search*" -print0 |
        while IFS= read -r -d '' file; do
            local new
            new=${file//$search/$replace}
            if [[ $file != "$new" ]]; then
                mv -v -- "$file" "$new"
            fi
        done
}


function dotfind() {
    ### Find folders with dots in names up to depth 2
    find . -maxdepth 2 -type d -regex '.*/[^./][^/]*\.[^/]*'
}

function reverseempty() {
    local target="${1:-.}"
    if [ $# -gt 1 ] || [ ! -d "$target" ]; then
        echo "Usage: reverseempty [folder_path] [music|movies|epub]"
        return 1
    fi
    local type="${2:-music}" cmd depth=1 msg
    case "${type,,}" in
        music)
            cmd='find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a'
            msg="music files";;
        movies|movie)
            cmd='find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.mp4" -o -iname "*.wmv" -o -iname "*.m4v" \) -type f | read a'
            msg="movie files";;
        epub|epubs|epubs)
            cmd='find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a'
            msg="epub files"; depth=2;;
        *)
            echo "Unknown category: $type (use music|movies|epub)"
            return 1;;
    esac
    echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing $msg in $target"
    find "$target" -maxdepth "$depth" -mindepth "$depth" -type d ! -exec sh -c "$cmd" _ {} \; -print
}

# function reverseempty() {
#     ### Find folders not containing certain media file types
#     if [ $# -ne 1 ]; then
#         echo "Usage: reverseempty <music|movies|epub>"
#         return 1
#     fi
#     case "$1" in
#         music)
#             echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing music files in $PWD"
#             find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c \
#                 'find "$1" \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.m4a" \) -type f | read a' _ {} \; -print
#             ;;
#         movie|movies)
#             echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing movie files in $PWD"
#             find . -maxdepth 1 -mindepth 1 -type d \! -exec sh -c \
#                 'find "$1" \( -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.vob" -o -iname "*.mp4" -o -iname "*.wmv" -o -iname "*.m4v" \) -type f | read a' _ {} \; -print
#             ;;
#         epubs|ePubs|epub)
#             echo -e "Searching for folders ${ORANGE:-}NOT${NC:-} containing epub files in $PWD"
#             find . -maxdepth 2 -mindepth 2 -type d \! -exec sh -c \
#                 'find "$1" \( -iname "*.epub" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.pdf" \) -type f | read a' _ {} \; -print
#             ;;
#         *)
#             echo "Unknown category: $1"
#             echo "Usage: reverseempty <music|movies|epub>"
#             return 1
#             ;;
#     esac
# }



# function funchelp() {
#     ### List all custom functions available
#     echo "Custom functions available:"
#     typeset -f | awk '/ \(\) $/ && !/^main / {print $1}' | grep -v '^_'
# }

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

# Might be better as an alias, but here for completeness
# remove if not working as intended
function cd() {
    ### Override cd to show ls after entering directory
    builtin cd "$@" || return
    [[ $- == *i* ]] && ls
}

function get_os() {
    ### Detect OS and export global system variables
    # shellcheck disable=SC2034

    OS=$(uname -s)
    KERNEL=$(uname -r)
    MACH=$(uname -m)

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=$NAME
        DISTRO_BASE=$ID
    else
        DISTRO="unknown"
        DISTRO_BASE="unknown"
    fi

    export OS KERNEL MACH DISTRO DISTRO_BASE
}


# function get_os() {
#     ### Detect OS and distribution information
#     OS=$(uname -s | tr '[:upper:]' '[:lower:]')
#     KERNEL=$(uname -r)
#     MACH=$(uname -m)
#     DISTRO="unknown"
#     DISTRO_BASE="unknown"
    
#     if [ -f /etc/os-release ]; then
#         source /etc/os-release
#         DISTRO="${ID:-unknown}"
#         DISTRO_BASE="${ID_LIKE:-$DISTRO}"
#     elif [ -f /etc/lsb-release ]; then
#         source /etc/lsb-release
#         DISTRO="${DISTRIB_ID:-unknown}"
#         DISTRO_BASE="$DISTRO"
#     fi
    
#     export OS KERNEL MACH DISTRO DISTRO_BASE
    
#     # Display the values
#     echo "OS: $OS"
#     echo "KERNEL: $KERNEL"
#     echo "MACH: $MACH"
#     echo "DISTRO: $DISTRO"
#     echo "DISTRO_BASE: $DISTRO_BASE"
# }

# function setting_standard_commands() {
#     ### Set package manager aliases based on distribution
#     # Get OS info if not already set
#     if [ -z "$DISTRO_BASE" ]; then
#         get_os >/dev/null
#     fi
    
#     case "$DISTRO_BASE" in
#         debian*|ubuntu*)
#             alias install="sudo apt-get install -y"
#             alias uninstall="sudo apt-get remove -y"
#             alias update="sudo apt-get update && sudo apt-get upgrade -y"
#             ;;
#         rhel*|redhat*|centos*|fedora*)
#             if command -v dnf >/dev/null 2>&1; then
#                 alias install="sudo dnf install -y"
#                 alias uninstall="sudo dnf remove -y"
#                 alias update="sudo dnf update -y"
#             else
#                 alias install="sudo yum install -y"
#                 alias uninstall="sudo yum remove -y"
#                 alias update="sudo yum update -y"
#             fi
#             ;;
#         arch*)
#             alias install="sudo pacman -Syu --noconfirm"
#             alias uninstall="sudo pacman -Rns --noconfirm"
#             alias update="sudo pacman -Syu --noconfirm"
#             ;;
#         gentoo*)
#             alias install="sudo emerge"
#             alias uninstall="sudo emerge --unmerge"
#             alias update="sudo emerge --update --deep --newuse @world"
#             ;;
#         *)
#             echo "Unknown OS base: $DISTRO_BASE"
#             return 1
#             ;;
#     esac
#     echo "Package manager aliases set for $DISTRO_BASE"
# }

function functions() {
    ### List function names or descriptions with -?
    local func_file="$HOME/dotfiles/.bashrc.d/functions.bash"
    
    if [[ "$1" == "-?" || "$1" == "--help" ]]; then
        if [[ -f "$func_file" ]]; then
            local count
            count=$(awk '/^function [a-zA-Z_][a-zA-Z0-9_-]+/ {count++} END {print count+0}' "$func_file")
            echo "Available functions ($count) & description:"
            
            awk '
            # Capture function name (no parens in output)
            /^function [a-zA-Z_][a-zA-Z0-9_-]+/ {
                # Extract just the function name, removing () if present
                match($2, /^[a-zA-Z_][a-zA-Z0-9_-]+/)
                fname = substr($2, RSTART, RLENGTH)
                desc = "(no description)"
                
                # Check CURRENT line first
                if ($0 ~ /###/) {
                    # Remove everything up to and including ###
                    sub(/^[^#]*###[[:space:]]*/, "")
                    desc = $0
                } else {
                    # Save current position and check next line
                    savedline = $0
                    if ((getline nextline) > 0 && nextline ~ /###/) {
                        sub(/^[[:space:]]*###[[:space:]]*/, "", nextline)
                        desc = nextline
                    }
                }
                printf "  %-25s %s\n", fname, desc
                next
            }
            ' "$func_file"
        else
            echo "Could not find function source file: $func_file" >&2
            return 1
        fi
    else
        declare -F | awk '{print $3}' | sed 's/^[0-9]*://' | grep -v '^_' | column -c 80
    fi
}

# Set up version command (fastfetch or neofetch)
if command -v fastfetch >/dev/null 2>&1; then
    version() { fastfetch "$@"; }
elif command -v neofetch >/dev/null 2>&1; then
    version() { neofetch "$@"; }
else
    version() {
        ### Shows system information using neofetch or fastfetch
        echo "⚠️  'version' command not found. Install neofetch or fastfetch?"
        read -r -p "Install (n)eofetch, (f)astfetch, or (c)ancel? [n/f/c]: " choice
        case "$choice" in
            n|N)
                echo "Installing neofetch..."
                # Use p_install if available, otherwise fall back to direct apt
                if command -v p_install >/dev/null 2>&1; then
                    p_install neofetch && neofetch
                elif command -v apt-get >/dev/null 2>&1; then
                    sudo apt-get install -y neofetch && neofetch
                else
                    echo "Error: Could not determine package manager"
                    return 1
                fi
                ;;
            f|F)
                echo "Installing fastfetch..."
                # Use p_install if available, otherwise fall back to direct apt
                if command -v p_install >/dev/null 2>&1; then
                    p_install fastfetch && fastfetch
                elif command -v apt-get >/dev/null 2>&1; then
                    sudo apt-get install -y fastfetch && fastfetch
                else
                    echo "Error: Could not determine package manager"
                    return 1
                fi
                ;;
            *)
                echo "Installation cancelled."
                ;;
        esac
    }
fi
