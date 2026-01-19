#!/usr/bin/env bash
# =================================================================================================
# pkg_aliases.bash - COMPLETE CROSS-DISTRO PACKAGE MANAGER (p_* functions + aliases)
# =================================================================================================
# Purpose: Universal p_install/p_update/p_upgrade/p_search + convenient aliases.
# Dependencies: None (early load).
# Usage: set_package_aliases → use p_install pkgname OR install pkgname (alias)
# 
# Functions use p_* prefix to avoid conflicts with /usr/bin/install
# Aliases provide convenient shorthand for interactive use
# =================================================================================================

# Helper: command_check (if not loaded)
command_check() { command -v "$1" >/dev/null 2>&1; }

# SUDOCMD detect
if command_check sudo; then
    SUDOCMD="sudo"
elif command_check doas; then
    SUDOCMD="doas"
else
    SUDOCMD=""
    echo "Warning: No sudo/doas - pkg cmds may fail" >&2
fi
export SUDOCMD

function set_package_aliases() {
    local DISTROBASE_LOCAL
    
    # Distro detect (orig safe source)
    if [[ -n "$DISTROBASE" ]]; then
        DISTROBASE_LOCAL="$DISTROBASE"
    else
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            # Use ID first, then ID_LIKE as fallback
            DISTROBASE_LOCAL="${ID:-unknown}"
            # Debug output
            [[ -n "${DEBUG:-}" ]] && echo "DEBUG: ID=$ID, ID_LIKE=$ID_LIKE, Using: $DISTROBASE_LOCAL" >&2
        elif [[ "$(uname -s)" == "Darwin" ]]; then
            DISTROBASE_LOCAL="macos"
        else
            DISTROBASE_LOCAL="$(uname -s | tr '[:upper:]' '[:lower:]')"
        fi
    fi
    
    # Normalize/export (use lowercase ID for matching)
    DISTROBASE="$(echo "$DISTROBASE_LOCAL" | tr '[:upper:]' '[:lower:]')"
    export DISTROBASE
    
    # Debug output
    [[ -n "${DEBUG:-}" ]] && echo "DEBUG: DISTROBASE_LOCAL='$DISTROBASE_LOCAL', DISTROBASE='$DISTROBASE'" >&2
    
    case "$DISTROBASE" in
        debian|ubuntu|linuxmint|pop)
            # Debian/Ubuntu
            p_install() { "$SUDOCMD" apt-get install -y "$@"; }
            p_remove() { "$SUDOCMD" apt-get remove -y "$@"; }
            p_uninstall() { "$SUDOCMD" apt-get remove -y "$@"; }
            p_update() { "$SUDOCMD" apt-get update; }
            p_upgrade() { "$SUDOCMD" apt-get update && "$SUDOCMD" apt-get upgrade -y; }
            p_search() { apt-cache search "$@"; }
            p_clean() { "$SUDOCMD" apt-get autoremove -y && "$SUDOCMD" apt-get autoclean; }
            p_info() { apt-cache show "$@"; }
            ;;
        
        redhat|centos|fedora|almalinux|rocky|rhel)
            # RHEL/Fedora (dnf/yum detect)
            if command_check dnf; then
                p_install() { "$SUDOCMD" dnf install -y "$@"; }
                p_remove() { "$SUDOCMD" dnf remove -y "$@"; }
                p_uninstall() { "$SUDOCMD" dnf remove -y "$@"; }
                p_update() { "$SUDOCMD" dnf check-update; }
                p_upgrade() { "$SUDOCMD" dnf upgrade -y "$@"; }
                p_search() { dnf search "$@"; }
                p_clean() { "$SUDOCMD" dnf autoremove -y && "$SUDOCMD" dnf clean all; }
                p_info() { dnf info "$@"; }
            else
                p_install() { "$SUDOCMD" yum install -y "$@"; }
                p_remove() { "$SUDOCMD" yum remove -y "$@"; }
                p_uninstall() { "$SUDOCMD" yum remove -y "$@"; }
                p_update() { "$SUDOCMD" yum check-update; }
                p_upgrade() { "$SUDOCMD" yum update -y "$@"; }
                p_search() { yum search "$@"; }
                p_clean() { "$SUDOCMD" yum autoremove -y && "$SUDOCMD" yum clean all; }
                p_info() { yum info "$@"; }
            fi
            ;;
        
        opensuse|opensuse-tumbleweed|opensuse-leap|suse|sles)
            # openSUSE (all variants)
            p_install() { "$SUDOCMD" zypper install -y "$@"; }
            p_remove() { "$SUDOCMD" zypper remove -y "$@"; }
            p_uninstall() { "$SUDOCMD" zypper remove -y "$@"; }
            p_update() { "$SUDOCMD" zypper refresh; }
            p_upgrade() { "$SUDOCMD" zypper update -y "$@"; }
            p_search() { zypper search "$@"; }
            p_clean() { "$SUDOCMD" zypper clean -a; }
            p_info() { zypper info "$@"; }
            ;;
        
        arch|manjaro|endeavouros)
            # Arch
            p_install() { "$SUDOCMD" pacman -S --noconfirm "$@"; }
            p_remove() { "$SUDOCMD" pacman -Rns --noconfirm "$@"; }
            p_uninstall() { "$SUDOCMD" pacman -Rns --noconfirm "$@"; }
            p_update() { "$SUDOCMD" pacman -Sy; }
            p_upgrade() { "$SUDOCMD" pacman -Syu --noconfirm; }
            p_search() { pacman -Ss "$@"; }
            p_clean() { "$SUDOCMD" pacman -Sc --noconfirm; }
            p_info() { pacman -Si "$@"; }
            ;;
        
        gentoo)
            # Gentoo
            p_install() { "$SUDOCMD" emerge -av "$@"; }
            p_remove() { "$SUDOCMD" emerge --unmerge "$@"; }
            p_uninstall() { "$SUDOCMD" emerge --unmerge "$@"; }
            p_update() { "$SUDOCMD" emerge --sync; }
            p_upgrade() { "$SUDOCMD" emerge --update --deep --newuse @world; }
            p_search() { emerge --search "$@"; }
            p_clean() { "$SUDOCMD" emerge --depclean; }
            p_info() { emerge --info "$@"; }
            ;;
        
        alpine)
            # Alpine
            p_install() { "$SUDOCMD" apk add "$@"; }
            p_remove() { "$SUDOCMD" apk del "$@"; }
            p_uninstall() { "$SUDOCMD" apk del "$@"; }
            p_update() { "$SUDOCMD" apk update; }
            p_upgrade() { "$SUDOCMD" apk upgrade; }
            p_search() { apk search "$@"; }
            p_clean() { "$SUDOCMD" apk cache clean; }
            p_info() { apk info "$@"; }
            ;;
        
        void)
            # Void
            p_install() { "$SUDOCMD" xbps-install -y "$@"; }
            p_remove() { "$SUDOCMD" xbps-remove -y "$@"; }
            p_uninstall() { "$SUDOCMD" xbps-remove -y "$@"; }
            p_update() { "$SUDOCMD" xbps-install -S; }
            p_upgrade() { "$SUDOCMD" xbps-install -Su; }
            p_search() { xbps-query -Rs "$@"; }
            p_clean() { "$SUDOCMD" xbps-remove -yo; }
            p_info() { xbps-query -R "$@"; }
            ;;
        
        nixos|nix)
            # NixOS
            p_install() { nix-env -iA "$@"; }
            p_remove() { nix-env -e "$@"; }
            p_uninstall() { nix-env -e "$@"; }
            p_update() { nix-channel --update; }
            p_upgrade() { nix-env -u "$@"; }
            p_search() { nix search nixpkgs "$@"; }
            p_clean() { nix-collect-garbage -d; }
            p_info() { nix-env -qa --description "$@"; }
            ;;
        
        freebsd)
            # FreeBSD
            p_install() { "$SUDOCMD" pkg install -y "$@"; }
            p_remove() { "$SUDOCMD" pkg delete -y "$@"; }
            p_uninstall() { "$SUDOCMD" pkg delete -y "$@"; }
            p_update() { "$SUDOCMD" pkg update; }
            p_upgrade() { "$SUDOCMD" pkg upgrade -y; }
            p_search() { pkg search "$@"; }
            p_clean() { "$SUDOCMD" pkg autoremove -y && "$SUDOCMD" pkg clean -y; }
            p_info() { pkg info "$@"; }
            ;;
        
        openbsd)
            # OpenBSD
            p_install() { "$SUDOCMD" pkg_add "$@"; }
            p_remove() { "$SUDOCMD" pkg_delete "$@"; }
            p_uninstall() { "$SUDOCMD" pkg_delete "$@"; }
            p_update() { "$SUDOCMD" pkg_add -u; }
            p_upgrade() { "$SUDOCMD" pkg_add -u; }
            p_search() { pkg_info -Q "$@"; }
            p_clean() { "$SUDOCMD" pkg_delete -a; }
            p_info() { pkg_info "$@"; }
            ;;
        
        macos|darwin)
            # macOS Homebrew
            if command_check brew; then
                p_install() { brew install "$@"; }
                p_remove() { brew uninstall "$@"; }
                p_uninstall() { brew uninstall "$@"; }
                p_update() { brew update; }
                p_upgrade() { brew upgrade "$@"; }
                p_search() { brew search "$@"; }
                p_clean() { brew cleanup; }
                p_info() { brew info "$@"; }
            else
                echo "Homebrew not installed. Install from https://brew.sh" >&2
                return 1
            fi
            ;;
        
        *)
            echo "Unknown OS: $DISTROBASE_LOCAL"
            echo "Package manager functions not configured."
            echo "Supported: Debian/Ubuntu/RHEL/Arch/Gentoo/Alpine/Void/NixOS/FreeBSD/OpenBSD/macOS/openSUSE"
            return 1
            ;;
    esac
    
    # Export all p_* functions for subshells
    export -f p_install p_remove p_uninstall p_update p_upgrade p_search p_clean p_info
    
    # Create convenient aliases ONLY in interactive shells
    # These won't interfere with scripts/RunMe.sh which use p_* directly
    if [[ $- == *i* ]]; then
        alias install='p_install'
        alias remove='p_remove'
        alias uninstall='p_uninstall'
        alias update='p_update'
        alias upgrade='p_upgrade'
        alias search='p_search'
        alias clean='p_clean'
        alias info='p_info'
    fi
    
    echo "Package functions configured for $DISTROBASE_LOCAL"
}

# Auto-init ONLY in interactive shells
if [[ $- == *i* ]]; then
    set_package_aliases
fi

# Export the function
export -f set_package_aliases