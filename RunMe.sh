#!/usr/bin/env bash

# Dotfiles Installer Script
# Backups old dotfiles, creates symlinks, installs apps, manages submodules

set -euo pipefail

DEBUG=1
TRACE_DEBUG=0
SLEEP=2
DIR="$HOME/dotfiles/oldfiles"
LOG="$DIR/dotfile_install_$(date +%Y-%m-%d).log"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
TITLE="Dotfiles Installer Script"
FILE="$HOSTNAME-$DATE.zip"
APP_ARRAY=(curl htop ncdu pydf tree tmux vim mc fd-find git bat deborphan)
DOT_ARRAY=("$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.inputrc")
OLD_FILE_ARRAY=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.inputrc" "$HOME/.cshrc" "$HOME/.login")
ACTIONS=()

log() {
    echo "$*" | tee -a "$LOG"
    ACTIONS+=("$*")
    sleep "$SLEEP"
}
logfile_init() {
    mkdir -p "$DIR"
    : > "$LOG"
    log "$TITLE - $DATE"
}

if [[ "$TRACE_DEBUG" -eq 1 ]]; then
    set -x
    trap read DEBUG
fi

if [[ "$EUID" -eq 0 ]]; then
    echo "Please don't run this script as root!"
    exit 1
fi

check_or_add_line() {
    local line="$1" file="$2"
    if grep -qxF "$line" "$file"; then
        log "Line already exists in $file: $line"
    else
        echo "$line" >> "$file"
        log "Added line to $file: $line"
    fi
}

get_os_info() {
    local os kernel mach
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    kernel="$(uname -r)"
    mach="$(uname -m)"
    DISTRO="unknown"
    DISTRO_BASE="unknown"

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_BASE="${ID_LIKE:-$DISTRO}"
    fi

    export OS="$os" KERNEL="$kernel" MACH="$mach" DISTRO DISTRO_BASE
    log "Detected OS: $OS, Distro: $DISTRO, Base: $DISTRO_BASE"
}

set_package_aliases() {
    case "$DISTRO_BASE" in
        debian*|ubuntu*)
            alias install='sudo apt-get install -y'
            alias remove='sudo apt-get remove -y'
            alias update='sudo apt-get update && sudo apt-get upgrade -y'
            ;;
        redhat*|centos*|fedora*)
            alias install='sudo yum install -y'
            alias remove='sudo yum remove -y'
            alias update='sudo yum update -y'
            ;;
        arch*)
            alias install='sudo pacman -Syu --noconfirm'
            alias remove='sudo pacman -Rns --noconfirm'
            alias update='sudo pacman -Syu --noconfirm'
            ;;
        gentoo*)
            alias install='sudo emerge'
            alias remove='sudo emerge --unmerge'
            alias update='sudo emerge --update --deep @world'
            ;;
        *)
            log "No supported package manager aliases for base: $DISTRO_BASE"
            ;;
    esac
}

install_apps() {
    for app in "${APP_ARRAY[@]}"; do
        if ! command -v "$app" &>/dev/null; then
            log "Installing $app"
            install "$app" || log "Failed to install $app"
        else
            log "$app already installed"
        fi
    done
}

backup_dotfiles() {
    for f in "${OLD_FILE_ARRAY[@]}"; do
        if [[ -f "$f" ]]; then
            cp -p "$f" "$DIR/"
            log "Backed up $f to $DIR/"
        fi
    done
}

cleanup_symlinks() {
    for file in "${DOT_ARRAY[@]}"; do
        if [[ -L "$file" && ! -e "$file" ]]; then
            rm -f "$file"
            log "Removed broken symlink: $file"
        elif [[ -e "$file" && ! -L "$file" ]]; then
            mv "$file" "$DIR/"
            log "Moved existing file $file to $DIR/"
        fi
    done
}

symlink_dotfiles() {
    for src in "${DOT_ARRAY[@]}"; do
        target="$HOME/dotfiles/$(basename "$src")"
        ln -sf "$target" "$src"
        log "Symlinked $target -> $src"
    done
}

archive_backup() {
    local archived="$DIR/$FILE"
    if compgen -G "$DIR/*" > /dev/null; then
        zip -r -q "$archived" "$DIR"/*.*
        log "Archived old dotfiles into $archived"
    else
        log "No files to archive"
    fi
}

update_submodules() {
    git submodule update --init --recursive
    git submodule foreach git pull origin master || :
    log "Updated all submodules"
}

clone_repos() {
    cd "$HOME" || return
    log "Cloning tmux and vim repos..."
    git clone --recurse-submodules git@bitbucket.org:b0red/tmux.git .tmux || log "tmux repo clone failed"
    git clone --recurse-submodules git@bitbucket.org:b0red/.vim.git .vim || log ".vim repo clone failed"
}

add_tmux_line() {
    check_or_add_line "if [[ \$TMUX ]]; then source ~/.tmux/extras/tmux-git/tmux-git.sh; fi" "$HOME/.bashrc"
}

revert_changes() {
    log "Reverting changes..."
    if [[ -d "$DIR" ]]; then
        for f in "$DIR"/*; do
            [ -f "$f" ] && cp -pf "$f" "$HOME/$(basename "$f")" && log "Restored $(basename "$f") from backup"
        done
    fi
    for src in "${DOT_ARRAY[@]}"; do
        if [[ -L "$src" ]]; then
            rm -f "$src"
            log "Removed symlink $src during revert"
        fi
    done
    log "Revert step completed."
    log ""
    echo "==== Revert Summary ===="
    printf '%s\n' "${ACTIONS[@]}"
    echo "Log file: $LOG"
}

main() {
    logfile_init
    get_os_info
    set_package_aliases
    backup_dotfiles
    cleanup_symlinks
    symlink_dotfiles
    install_apps
    archive_backup
    update_submodules
    clone_repos
    add_tmux_line
    source "$HOME/.bashrc"
    log "All steps completed for $TITLE"
    log ""
    echo "==== Install Summary ===="
    printf '%s\n' "${ACTIONS[@]}"
    echo "Log file: $LOG"
}

case "${1:-}" in
    -\?|-\h|--help)
        [[ "$1" == "-?" ]] && { echo "Usage: RunMe.sh [-?, -h, --help, -r, --revert]"; exit 0; }
        cat <<EOF
RunMe.sh - Dotfiles installer script

Options:
  -?            Show short usage
  -h, --help    Show this help message
  -r, --revert  Restore backup dotfiles and remove symlinks

Description:
This script backs up existing dotfiles, creates symlinks to the new dotfiles,
installs common packages, and manages git submodules.

EOF
        exit 0
        ;;
    -r|--revert)
        logfile_init
        revert_changes
        exit 0
        ;;
    "")
        main "$@"
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: RunMe.sh [-?, -h, --help, -r, --revert]"
        exit 1
        ;;
esac

exit 0
