#!/bin/bash

# CHANGES: Use the repository directory as the source instead of $(pwd)
# and avoid creating self-referential links in the default case.
# Resolve repository directory (the directory of this script)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Symlink helper function with backup if target file exists
function linkwork() {
    local linkTocheck="$1"
    local sourceLink="$2"
    if [ -f "$linkTocheck" ]; then
        echo "$linkTocheck is a file - backing it up"
        mv "$linkTocheck" "$linkTocheck.bak"
    fi
    if [ ! -h "$linkTocheck" ]; then
        ln -s "$sourceLink" "$linkTocheck"
        echo "$linkTocheck created"
    fi
}

if [ "$(uname -s)" = "Linux" ]; then
    distro_id=$(grep ^ID= /etc/os-release | sed 's/ID=//;s/"//g')
    home_dir="/home/$(whoami)"
    case "$distro_id" in
        kali)
            linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
            linkwork "$home_dir/.kali_profile" "$REPO_DIR/.kali_profile"
            linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
            linkwork "$home_dir/.vimrc" "$REPO_DIR/.vimrc"
            linkwork "$home_dir/.tmux.conf" "$REPO_DIR/.tmux.conf"
            linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
            ;;
        raspbian)
            linkwork "$home_dir/.rpi_profile" "$REPO_DIR/.rpi_profile"
            ;;
        ubuntu)
            linkwork "$home_dir/.ubu_profile" "$REPO_DIR/.ubu_profile"
            ;;
        centos)
            linkwork "$home_dir/.centos_profile" "$REPO_DIR/.centos_profile"
            ;;
        *)
            # Default -> link home files to repo versions (avoid self-linking)
            linkwork "$home_dir/.tmux.conf" "$REPO_DIR/.tmux.conf"
            linkwork "$home_dir/.vimrc" "$REPO_DIR/.vimrc"
            linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
            linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
            linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
            ;;
    esac
fi 