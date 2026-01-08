#!/usr/bin/env bash
# RunMe.sh — Dotfiles installer for first-run setup on new systems
# Backs up old files, symlinks dotfiles, installs apps, updates submodules.
# Supports WSL/Ubuntu, reloads .bashrc/aliases automatically.

set -euo pipefail

# Global recursion guard
if [ -n "${RUNME_INITIATED:-}" ]; then
    echo "RunMe.sh already running (PID $$)" >&2
    exit 1
fi
RUNME_INITIATED=1
export RUNME_INITIATED

# Configuration variables   
DEBUG=${DEBUG:-0}
TRACE_DEBUG=${TRACE_DEBUG:-0}
SLEEP=${SLEEP:-2}
DIR="$HOME/dotfiles"
OLD_FILES="$DIR/old-files"
LOG_DIR="$DIR/install-$(date +%Y-%m-%d).log"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
TITLE="Dotfiles Installer Script"
APP_ARRAY=(curl htop ncdu pydf tree tmux vim mc fd-find git bat)
DOT_ARRAY=("$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.inputrc")
OLD_FILE_ARRAY=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.inputrc" "$HOME/.cshrc" "$HOME/.login")

# Safe log (no unbound var)
log() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "${LOG:-/dev/stdin}"  # Fallback if LOG unset
}

ACTIONS() {
    log "$@"
    sleep "${SLEEP:-2}"
}

# # Load app list from external file (easy maintenance)
# # Load apps safely (no recursion)
# INSTALL_APPS_INC="$DIR/.install_apps.inc"
# if [ -r "$INSTALL_APPS_INC" ]; then
#     if . "$INSTALL_APPS_INC" 2>/dev/null; then
#         log "Loaded ${#APP_ARRAY[@]} apps from $INSTALL_APPS_INC"
#     else
#         log "Warning: $INSTALL_APPS_INC syntax error; empty array"
#         declare -a APP_ARRAY=()
#     fi
# else
#     log "No $INSTALL_APPS_INC; empty APP_ARRAY"
#     declare -a APP_ARRAY=()
# fi


logfile_init() {
    mkdir -p "$LOG_DIR"
    LOG="$LOG_DIR/install-$DATE.log"
    if [ ! -t 1 ]; then return; fi  # Skip tee if piped
    exec > >(tee -a "$LOG")
    exec 2>&1
    log "$TITLE started (PID $$)"
}

if [ "$TRACE_DEBUG" -eq 1 ]; then set -x; trap 'read -p "DEBUG: Press Enter..."' DEBUG; fi

if [ "$EUID" -eq 0 ]; then
    echo "Please don't run as root!"
    exit 1
fi

check_or_add_line() {
    local line="$1" file="$2"
    if [ ! -f "$file" ]; then
        touch "$file"  # Create empty if missing
        log "Created empty $file for guards"
    fi
    if grep -qxF "$line" "$file" 2>/dev/null; then
        log "Line already exists in $file: $line"
    else
        echo "$line" >> "$file"
        log "Added line to $file: $line"
    fi
}

get_os_info() {
    local os kernel mach
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    kernel=$(uname -r)
    mach=$(uname -m)
    DISTRO="unknown"
    DISTRO_BASE="unknown"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_BASE="${ID_LIKE:-$ID}"
    fi
    export OS="$os" KERNEL="$kernel" MACH="$mach" DISTRO DISTRO_BASE
    log "Detected OS: $OS, Distro: $DISTRO, Base: $DISTRO_BASE"
}

set_package_aliases() {
    if [ -z "$DISTRO_BASE" ]; then
        DISTRO_BASE=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]' || \
                      grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]' || \
                      uname -s | tr '[:upper:]' '[:lower:]')
        export DISTRO_BASE
    fi
    log "Detected DISTRO_BASE: $DISTRO_BASE"

    case "$DISTRO_BASE" in
        debian*|ubuntu*)
            alias install='sudo apt-get install -y'
            alias {remove,uninstall}='sudo apt-get remove -y'
            alias update='sudo apt-get update && sudo apt-get upgrade -y'
            ;;
        redhat*|centos*|fedora*|almalinux*|rocky*|rhel*)
            if command -v dnf >/dev/null; then
                alias install='sudo dnf install -y'
                alias {remove,uninstall}='sudo dnf remove -y'
                alias update='sudo dnf update -y'
            else
                alias install='sudo yum install -y'
                alias {remove,uninstall}='sudo yum remove -y'
                alias update='sudo yum update -y'
            fi
            ;;
        opensuse*|suse*)
            alias install='sudo zypper install -y'
            alias {remove,uninstall}='sudo zypper remove -y'
            alias update='sudo zypper update -y'
            ;;
        arch*|manjaro*)
            alias install='sudo pacman -Syu --noconfirm'
            alias {remove,uninstall}='sudo pacman -Rns --noconfirm'
            alias update='sudo pacman -Syu --noconfirm'
            ;;
        gentoo*)
            alias install='sudo emerge -av'
            alias {remove,uninstall}='sudo emerge --unmerge'
            alias update='sudo emerge --update --deep @world'
            ;;
        freebsd*)
            alias install='sudo pkg install -y'
            alias {remove,uninstall}='sudo pkg delete -y'
            alias update='sudo pkg upgrade -y'
            ;;
        *)
            log "No supported package manager aliases for base: $DISTRO_BASE"
            return 1
            ;;
    esac
    log "Aliases set for $DISTRO_BASE: install, remove, update"
    # Reload aliases immediately for current session (first-run fix)
    source /dev/stdin <<< "$(alias | grep 'alias install\|alias {remove,uninstall}\|alias update')"
}

install_apps() {
    # Ensure aliases expand (shopt required for subshells/scripts)
    shopt -s expand_aliases
    
    for app in "${APP_ARRAY[@]}"; do
        if ! command -v "$app" >/dev/null 2>&1; then
            log "Installing $app"
            # Use quoted eval to force alias expansion safely
            if ! eval install "'$app'"; then
                log "Alias failed for $app; fallback to apt"
                sudo apt-get install -y "$app" || log "apt install $app also failed"
            fi
        else
            log "$app already installed"
        fi
    done
}

backup_dotfiles() {
    mkdir -p "$OLD_FILES"
    for f in "${OLD_FILE_ARRAY[@]}"; do
        if [ -f "$f" ]; then
            cp -p "$f" "$OLD_FILES/"
            log "Backed up $f to $OLD_FILES/"
        fi
    done
}

cleanup_symlinks() {
    for file in "${DOT_ARRAY[@]}"; do
        if [ -L "$file" ] && [ ! -e "$file" ]; then
            rm -f "$file"
            log "Removed broken symlink $file"
        elif [ -e "$file" ] && [ ! -L "$file" ]; then
            mv "$file" "$OLD_FILES/"
            log "Moved existing $file to $OLD_FILES/"
        fi
    done
}

symlink_dotfiles() {
    [ -d "$DIR" ] || { log "Error: $DIR not found. Clone repo first."; exit 1; }
    
    # Add recursion guards to prevent infinite loops (deborphan/bashrc issue)
    check_or_add_line '# Prevent recursion: if already sourced, exit early' "$HOME/.bashrc"
    check_or_add_line '[ -n "${BASHRC_SOURCED:-}" ] && return' "$HOME/.bashrc"
    check_or_add_line 'BASHRC_SOURCED=1' "$HOME/.bashrc"
    
    check_or_add_line '# Prevent recursion: if already sourced, exit early' "$HOME/.profile"
    check_or_add_line '[ -n "${PROFILE_SOURCED:-}" ] && return' "$HOME/.profile"
    check_or_add_line 'PROFILE_SOURCED=1' "$HOME/.profile"
    
    # Symlink core dotfiles
    for src in "${DOT_ARRAY[@]}"; do
        target="$DIR/$(basename "$src")"
        if [ ! -f "$target" ]; then
            log "Warning: $target missing in $DIR; skipping $(basename "$src")"
            continue
        fi
        # Remove existing, create symlink
        [ -e "$src" ] && rm -f "$src"
        ln -sf "$target" "$src"
        log "Symlinked $target → $src"
    done
    
    # Additional WSL-safe bash_profile loader (no loop)
    if [ ! -f "$HOME/.bash_profile" ] || ! grep -q ". ~/.bashrc" "$HOME/.bash_profile"; then
        check_or_add_line '# Load .bashrc for non-login interactive shells (WSL safe)' "$HOME/.bash_profile"
        check_or_add_line 'if [[ -n $PS1 && -f ~/.bashrc ]]; then . ~/.bashrc; fi' "$HOME/.bash_profile"
        log "Added WSL-safe .bash_profile loader"
    fi
    
    log "All symlinks created/guarded. Restart shell or source ~/.bashrc"
}

archive_backup() {
    local archived="$DIR/${HOSTNAME}-$DATE.zip"
    if compgen -G "$OLD_FILES/"* >/dev/null; then
        zip -r -q "$archived" "$OLD_FILES/"
        log "Archived old dotfiles into $archived"
    else
        log "No files to archive"
    fi
}

update_submodules() {
    cd "$DIR" || return
    git submodule update --init --recursive
    git submodule foreach --recursive git pull origin master
    log "Updated all submodules"
}

clone_repos() {
    cd "$HOME" || return
    
    log "Cloning tmux and .vim repos..."
    
    if [ ! -d ".tmux" ]; then
        if ! git clone --recurse-submodules https://bitbucket.org/b0red/tmux.git .tmux; then
            log "tmux repo clone failed (network/creds?)"
        else
            log "Cloned .tmux"
        fi
    else
        log ".tmux already exists; skipping"
    fi
    
    if [ ! -d ".vim" ]; then
        if ! GIT_TERMINAL_PROMPT=0 git -c core.askpass=echo clone --recurse-submodules https://bitbucket.org/b0red/.vim.git .vim; then
            log ".vim repo clone failed (network/creds/public repo)"
        else
            log "Cloned .vim"
        fi
    else
        log ".vim already exists; skipping"
    fi
}

add_tmux_line() {
    check_or_add_line 'if [ -f ~/.tmux-extras/tmux-gittmux-gittmux.sh ]; then source ~/.tmux-extras/tmux-gittmux-gittmux.sh; fi' "$HOME/.bashrc"
}

source_bashrc() {
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
        log ".bashrc sourced (aliases active)"
    fi
}

revert_changes() {
    log "Reverting changes..."
    if [ -d "$OLD_FILES" ]; then
        for f in "$OLD_FILES"/*; do
            [ -f "$f" ] || continue
            cp -pf "$f" "$HOME/$(basename "$f")"
            log "Restored $(basename "$f") from backup"
        done
    fi
    for src in "${DOT_ARRAY[@]}"; do
        if [ -L "$src" ]; then
            rm -f "$src"
            log "Removed symlink $src during revert"
        fi
    done
    log "Revert completed."
}

main() {
    logfile_init
    # fix_locale              # Add here: early, before aliases/apps
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
    source_bashrc
    log "All steps completed for $TITLE"
    ACTIONS "Install Summary: $(printf '%s\n' "${ACTIONS[@]}")"
    echo "Log: $LOG"
}

# Usage (safe for all modes)
show_help() {
    logfile_init  # Sets LOG safely
    cat << 'EOF'
Usage: ./RunMe.sh [OPTIONS]

Options:
  -?, -h, --help  Show this help
  -r, --revert    Restore backups, remove symlinks

Description: Backs up dotfiles, symlinks new ones, installs apps from .install_apps.inc,
updates submodules. Works on first run (sets/reloads aliases immediately).
Log: $LOG

EOF
}

case "${1:-}" in
    -?|-h|--help) show_help; exit 0 ;;
    -r|--revert) logfile_init; revert_changes; exit 0 ;;
    *) main "$@";;
esac

main "$@"
exit 0
