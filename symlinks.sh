#!/bin/bash
function linkwork()
{
    linkTocheck="$1"
    sourceLink="$2"
    if [ -f "$linkTocheck" ]; then
        echo "$linkTocheck is a file - backing it up"
        mv "$linkTocheck" "$sourceLink.bak"  
    fi
    if [ ! -h "$linkTocheck" ]; then
        ln -s "$sourceLink" "$linkTocheck"
        echo "$linkTocheck created"
    fi
}

if [ "Linux" = "$(uname -a | awk '{printf $1}')" ]
then
    if [ "kali" = "$(cat /etc/os-release | grep ^ID= |sed 's/ID=//')" ]
    then
        linkwork "/$(whoami)"/.common_profile "$(pwd)"/.common_profile
        linkwork "/$(whoami)"/.kali_profile "$(pwd)"/.kali_profile
        linkwork "/$(whoami)"/.bashrc "$(pwd)"/.bashrc 
        linkwork "/$(whoami)"/.vimrc "$(pwd)"/.vimrc 
        linkwork "/$(whoami)"/.tmux.conf "$(pwd)"/.tmux.conf  
        linkwork "/$(whoami)"/.gitconfig "$(pwd)"/.gitconfig  


    else
        linkwork "/$(whoami)"/.tmux.conf /home/"$(whoami)"/.tmux.conf
        linkwork "/$(whoami)"/.vimrc /home/"$(whoami)"/.vimrc
        linkwork "/$(whoami)"/.bashrc /home/"$(whoami)"/.bashrc
        linkwork "/$(whoami)"/.common_profile /home/"$(whoami)"/.common_profile
        linkwork "/$(whoami)"/.gitconfig /home/"$(whoami)"/.gitconfig
    fi

    if [ "raspbian" = "$(cat /etc/os-release | grep ^ID= |sed 's/ID=//')" ]; then
    then
        linkwork "/Users/$(whoami)/.rpi_profile"  "$(pwd)"/.rpi_profile
    fi
    if [ "ubuntu" = "$(cat /etc/os-release | grep ^ID= |sed 's/ID=//')" ]; then
    then
        linkwork "/Users/$(whoami)/.ubu_profile"  "$(pwd)"/.ubu_profile
    fi
    if [ "centos" = "$(cat /etc/os-release | grep ^ID= |sed 's/ID=//')" ]; then
    then
        linkwork "/Users/$(whoami)/.centos_profile"  "$(pwd)"/.centos_profile
    fi


fi
echo 
