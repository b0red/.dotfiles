#!/bin/bash

# Function to create a symbolic link with backup of any existing file at the target
function linkwork() {
    local linkTocheck="$1"
    local sourceLink="$2"

    # If the target exists as a regular file, back it up by moving it to a .bak file
    if [ -f "$linkTocheck" ]; then
        echo "$linkTocheck is a file - backing it up"
        mv "$linkTocheck" "$linkTocheck.bak"
    fi

    # Only create symlink if it does NOT already exist as a symlink
    if [ ! -h "$linkTocheck" ]; then
        ln -s "$sourceLink" "$linkTocheck"
        echo "$linkTocheck created"
    fi
}

# Check if running on Linux based system
if [ "$(uname -s)" = "Linux" ]; then

    # Detect distribution ID from /etc/os-release for OS-specific symlink logic
    distro_id=$(grep ^ID= /etc/os-release | sed 's/ID=//;s/"//g')

    case "$distro_id" in
        kali)
            # On Kali, symlink user dotfiles from pwd to home directory named by whoami with leading slash removed
            home_dir="/home/$(whoami)"
            # Using absolute paths and proper home dir consistency
            linkwork "$home_dir/.common_profile" "$(pwd)/.common_profile"
            linkwork "$home_dir/.kali_profile" "$(pwd)/.kali_profile"
            linkwork "$home_dir/.bashrc" "$(pwd)/.bashrc"
            linkwork "$home_dir/.vimrc" "$(pwd)/.vimrc"
            linkwork "$home_dir/.tmux.conf" "$(pwd)/.tmux.conf"
            linkwork "$home_dir/.gitconfig" "$(pwd)/.gitconfig"
            ;;

        raspbian)
            # Raspberry Pi OS specific profile file
            linkwork "/home/$(whoami)/.rpi_profile" "$(pwd)/.rpi_profile"
            ;;

        ubuntu)
            # Ubuntu specific profile file
            linkwork "/home/$(whoami)/.ubu_profile" "$(pwd)/.ubu_profile"
            ;;

        centos)
            # CentOS specific profile file
            linkwork "/home/$(whoami)/.centos_profile" "$(pwd)/.centos_profile"
            ;;

        *)
            # Default for other Linux distributions
            home_dir="/home/$(whoami)"
            linkwork "$home_dir/.tmux.conf" "$home_dir/.tmux.conf" # Seems redundant but kept as original
            linkwork "$home_dir/.vimrc" "$home_dir/.vimrc"
            linkwork "$home_dir/.bashrc" "$home_dir/.bashrc"
            linkwork "$home_dir/.common_profile" "$home_dir/.common_profile"
            linkwork "$home_dir/.gitconfig" "$home_dir/.gitconfig"
            ;;
    esac
fi

# macOS logic commented out; if desired, can be uncommented and adjusted
: '
#if [ "$(sw_vers | grep ProductName | awk "{print \$2}")" = "Mac" ]; then
#    if [ "$(hostname)" = "home_computer" ]; then
#        linkwork "$HOME/.home_profile" "$(pwd)/.home_profile"
#    elif [ "$(hostname)" = "work-computer" ]; then
#        linkwork "$HOME/.work_profile" "$(pwd)/.work_profile"
#        source "$HOME/.work_profile"
#    fi
#    linkwork "$HOME/.tmux.conf" "$(pwd)/.tmux.conf"
#    linkwork "$HOME/.vimrc" "$(pwd)/.vimrc"
#    linkwork "$HOME/.common_profile" "$(pwd)/.common_profile"
#    linkwork "$HOME/.gitconfig" "$(pwd)/.gitconfig"
#fi
'

