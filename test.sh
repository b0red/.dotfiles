#!/bin/bash -p
###############################################################################################
##
##
##          This is just for testing
##          https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script
##
###############################################################################################

debug=1

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=$(uname); OS="${OS,,}"
KERNEL=$(uname -r)
MACH=$(uname -m)

if [ "${OS}" == "windowsnt" ]; then
    OS=windows
elif [ "${OS}" == "darwin" ]; then
    OS=mac
else
    OS="linux"
    if [ "${OS}" = "SunOS" ] ; then
        OS=Solaris
        ARCH=$(uname -p)
        OSSTR="${OS} ${REV}(${ARCH} "uname -v")"
    elif [ "${OS}" = "AIX" ] ; then
        OSSTR="${OS} "oslevel" ("oslevel -r")"
    elif [ "${OS}" = "linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='RedHat'
            DIST=$(cat /etc/redhat-release |sed s/\ release.*//)
            PSEUDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='SuSe'
            PSEUDONAME=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
            REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='Mandrake'
            PSEUDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='Debian'
            DIST=$(cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
            PSEUDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
            REV=$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST=$(${DIST}["cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//"])
        fi
        OS="${OS,,}"
        DistroBasedOn="${DistroBasedOn,,}"
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSEUDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
    fi

fi

if [ $debug -eq 1 ]; then
    echo "=============================="
        echo OS:        ${OS^}
        echo Distribution:      ${DIST^}
        echo Distro based on:       ${DistroBasedOn^}
        echo Pseudoname:        ${PSEUDONAME^}
        echo Revision:       ${REV^}
        echo Kernel:      ${KERNEL^}
        echo Machine:      $MACH
fi