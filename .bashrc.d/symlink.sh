#!/bin/bash

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
            linkwork "$home_dir/.common_profile" "$(pwd)/.common_profile"
            linkwork "$home_dir/.kali_profile" "$(pwd)/.kali_profile"
            linkwork "$home_dir/.bashrc" "$(pwd)/.bashrc"
            linkwork "$home_dir/.vimrc" "$(pwd)/.vimrc"
            linkwork "$home_dir/.tmux.conf" "$(pwd)/.tmux.conf"
            linkwork "$home_dir/.gitconfig" "$(pwd)/.gitconfig"
            ;;
        raspbian)
            linkwork "$home_dir/.rpi_profile" "$(pwd)/.rpi_profile"
            ;;
        ubuntu)
            linkwork "$home_dir/.ubu_profile" "$(pwd)/.ubu_profile"
            ;;
        centos)
            linkwork "$home_dir/.centos_profile" "$(pwd)/.centos_profile"
            ;;
        *)
            linkwork "$home_dir/.tmux.conf" "$home_dir/.tmux.conf"
            linkwork "$home_dir/.vimrc" "$home_dir/.vimrc"
            linkwork "$home_dir/.bashrc" "$home_dir/.bashrc"
            linkwork "$home_dir/.common_profile" "$home_dir/.common_profile"
            linkwork "$home_dir/.gitconfig" "$home_dir/.gitconfig"
            ;;
    esac
fi
