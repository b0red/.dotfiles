#!/usr/bin/env bash
###############################################################################################
##
##
##          This is just for testing
##          https://askubuntu.com/questions/1705/how-can-i-create-a-select-menu-in-a-shell-script
##
###############################################################################################
debug=1
SLEEP=0

function get_os() 
{
    #checks for os tyoe, this to alias right things
    OS=$(uname); OS="${OS,,}"
    KERNEL=$(uname -r)
    MACH=$(uname -m)
    if [ "${OS}" == "windowsnt" ]; then
        OS=windows; OSSYS="windows"
    elif [ "${OS}" == "darwin" ]; then
        OS=mac; OSSYS="mac"
    elif [ "${OS}" == "freebsd" ]; then
        OS=bsd; OSSYS="bsd"
        OSSTR=$(uname -rs)
    else
        OS="linux"
        if [ "${OS}" = "SunOS" ] ; then
            OS=Solaris; OSSYS="solaris"
            ARCH=$(uname -p)
            OSSTR="${OS} ${REV}(${ARCH} "uname -v")"
        elif [ "${OS}" = "AIX" ] ; then
            OSSTR="${OS} "oslevel" ("oslevel -r")"
        elif [ "${OS}" = "linux" ] ; then
            if [ -f /etc/redhat-release ] ; then
                DistroBasedOn='RedHat'; OSSYS="redhat"
                DIST=$(cat /etc/redhat-release |sed s/\ release.*//)
                PSEUDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
                REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
            elif [ -f /etc/SuSE-release ] ; then
                DistroBasedOn='SuSe'; OSSYS="suse"
                PSEUDONAME=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
                REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
            elif [ -f /etc/mandrake-release ] ; then
                DistroBasedOn='Mandrake'; OSSYS="mandrake"
                PSEUDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
                REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
            elif [ -f /etc/debian_version ] ; then
                DistroBasedOn='Debian'; OSSYS="debian"
                DIST=$(cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
                PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
                REV=$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')
            elif [ -f /etc/sabayon-edition ] ; then
                DistroBasedOn='Gentoo'; OSSYS="gentoo"
                DIST=$(cat /etc/*-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
                #PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
                REV=$(cat /etc/sabayon-edition | grep -Eo '[0-9][0-9]'.'[0-9][0-9]')    
            fi
            if [ -f /etc/UnitedLinux-release ] ; then
                DIST=$(${DIST}["cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//"])
                OSSYS="unitedlinux"
            fi
            OS="${OS,,}"
            DistroBasedOn="${DistroBasedOn,,}"
            #readnly make varaible readonly
            # readonly OS
            # readonly DIST
            # readonly DistroBasedOn
            # readonly PSEUDONAME
            # readonly REV
            # readonly KERNEL
            # readonly MACH
            # readonly OSSYS
            ###     export variables
            # export OS
            # export DIST
            # export DistroBasedOn
            # export PSEUDONAME
            # export REV
            # export KERNEL
            # export MACH
        fi
    fi
}

function setting_standard_commands() 
{
    case $OSSYS in
        solaris*) 
            [[ $debug -eq 1 ]] && echo "Setting alias' for: Solaris" || echo "Setting alias' for: Ssolaris" >> $LOG; sleep ${SLEEP}
            alias install="pkg install" $1
            alias {uninstall,remove}="pkg uninstall" $1
            alias app_search="pkg search" $1
            alias update="pkg update --accept" 
            os_status="solaris"
            ;;
        darwin*)  
            [[ $debug -eq 1 ]] && echo "Setting alias' for: OSX" || echo "Setting alias' for: OSX" >> $LOG; sleep ${SLEEP}
            os_status="Mac/Darwin"
            ;; 
        debian*)   
            [[ $debug -eq 1 ]] && echo "Setting alias' for: LINUX (Debian)" || echo "Setting alias' for: LINUX (Debian)" >> $LOG; sleep ${SLEEP}
            #alias rm='rm -i' 
            # Upgrade
            alias apt_update="sudo aptitude update"
            alias {sys_update,update,sysupdate}="sudo apt-get update && sudo apt-get upgrade"
            # install
            alias install="apt-get install" $1
            alias {uninstall,remove}="sudo apt remove"
            alias {sys_update,update,sysupdate}="sudo apt-get update && sudo apt-get upgrade"
            alias {sys_update,update,sysupdate}="sudo apt-get update && sudo apt-get upgrade"
            alias sysclean="sudo apt clean; sudo apt autoremove; sudo apt purge"
            alias installf="sudo apt -f install" #force install
            alias {reinnstall,installfr}="sudo apt -f install --rreinstall" # Force reinstall
            # Cleaning
            alias clean="sudo apt clean && sudo apt autoclean"
            alias remove="sudo apt remove && sudo apt autoremove"
            alias purge="sudo apt purge"
            alias deborphan="sudo deborphan | xaargs sudo apt -y remove --purge"
            alias apt_update="sudo aptitude update"
            alias apt_update="sudo aptitude update"
            # Network Start, Stop, and Restart
            alias networkrestart='sudo service networking restart'
            alias networkstop='sudo service networking stop'
            alias networkstart='sudo service networking start'
            os_status="Debian"
            ;;
        *bsd) 
            [[ $debug -eq 1 ]] && echo "Setting alias' for: *BSD" || echo "Setting alias' for: *BSD" >> $LOG; sleep ${SLEEP}
            alias install="pkg install " $1
            alias {uninstall,remove}="pkg deletei " $1
            alias {sys_update,sysup,sysupdate}="freebsd-update fetch && freebsd-update install"
            alias upgrade="pkg update && pkg upgrade"
            alias autoclean="pkg autoremove"
            alias clean="pkg clean -c"
            #unalias ll; alias ll=""
            os_status="*bsd"
            ;;
        redhat*)                                                           #     YUM (RedHat Linux, centos)
            [[ $debug -eq 1 ]] && echo "Setting alias' for: RedHat" || echo "Setting alias' for: RedHat" >> $LOG; sleep ${SLEEP}
            #PATH=$PATH:$HOME/bin
            alias install="sudo yum install -y" $1
            alias {uninstall,remove}="sudo yum remove" $1
            alias update="sudo yum update -y"
            alias upgrade="sudo yum upgrade -y"
            alias swap="sudo yum swap" $1 $2
            alias autoremove="sudo yum autoremove" $1
            alias reinstall="sudo yum reinstall" $1
            os_status="redhadt"
            ;;
        suse*)                                                            #     OpenSuSe)
            [[ $debug -eq 1 ]] && echo "Setting alias' for: OpenSuSe" || echo "Setting alias' for: OpenSuSe" >> $LOG; sleep ${SLEEP}
            alias install="zypper install" $1
            alias {uninstall,remove}="zypper remove" $1
            alias app_search="zypper search" $1
            alias update="sudo zypper refresh; sudo zypper dup"
            alias sysclean="sudo zypper clean -a"
            alias dist_upgrade="sudo zypper dist-upgrade"
            os_status="suse"
            ;;
        fedora*)                                                           #        Fedora
            [[ $debug -eq 1 ]] && echo "Setting alias' for: Fedora" || echo "Setting alias' for: Fedora" >> $LOG; sleep ${SLEEP}
            alias install="dnf install" $1
            alias {uninstall,remove}="dnf remove" $1
            alias upgrade="dnf upgrade"
            alias search="dnf search" $1
            alias autoremove="dnf remove" $1
            alias sysclean="dnf clean all"
            os_status="fedora"
            ;;
        pacman*)                                                           #        ArchLinux
            [[ $debug -eq 1 ]] && echo "Setting alias' for: ArchLinux" || echo "Setting alias' for: ArchLinux" >> $LOG; sleep ${SLEEP}
            alias install="pacman -Syu" $1
            alias {uninstall,remove}="pacman -Rsc" $1
            alias force_install="pacman -S --force" $1
            alias reinstall="pacman -Syu $(pacman -Qqen)"
            alias update="pacman -Syu"
            alias sysclean="pacman -Sc"
            alias package_list="pacman -Q"
            os_status="pacman"
            ;;
        msys*)    
            [[ $debug -eq 1 ]] && echo "Setting alias' for: CygWIN" || echo "Setting alias' for: CygWIN" >> $LOG; sleep ${SLEEP}
            os_status="ms Dos"
            ;;
        *)        
            [[ $debug -eq 1 ]] && echo "Unknown OS!" || echo "Unknown OS!" >> $LOG; sleep ${SLEEP} 
            os_status="I have no clue"
            ;;
    esac
}
clear
echo "function: get_os"; get_os
echo "function: standard_commands"; setting_standard_commands
echo -e "\nDistro: $DistroBasedOn"
echo "OS: $OS"
echo "Dist: $DIST"
echo "Rev: $REV"
3cho "PSEUDONAME: $PSEUDONAME"
echo "os_status: $os_status"
