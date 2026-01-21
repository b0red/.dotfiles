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
# 
# CRITICAL: NO GUARDS - Must work in both interactive AND non-interactive contexts!
# =================================================================================================

# =================================================================================================
# HELPER FUNCTIONS
# =================================================================================================

command_check() {
    command -v "$1" >/dev/null 2>&1
}


# Determine sudo command - check for sudo, doas, or run as root
if [[ $EUID -eq 0 ]]; then
    SUDOCMD=""
elif command_check sudo; then
    SUDOCMD="sudo"
elif command_check doas; then
    SUDOCMD="doas"
else
    SUDOCMD=""
    echo "Warning: No sudo/doas found - package commands may fail without root" >&2
fi
export SUDOCMD

# =================================================================================================
# MAIN FUNCTION: set_package_aliases
# =================================================================================================
function set_package_aliases() {
    local DISTROBASE_LOCAL
    
    # Distro detect - prioritize external DISTROBASE if set
    if [[ -n "$DISTROBASE" ]]; then
        DISTROBASE_LOCAL="$DISTROBASE"
    else
        # Detect from system
        local os
        os=$(uname -s | tr '[:upper:]' '[:lower:]')
        
        case "$os" in
            linux*)
                if [[ -f /etc/os-release ]]; then
                    . /etc/os-release
                    local distro="${ID:-unknown}"
                    
                    # Map distro to base family
                    case "$distro" in
                        ubuntu|debian|linuxmint|pop|peppermint|elementary|zorin)
                            DISTROBASE_LOCAL="debian"
                            ;;
                        rhel|centos|fedora|rocky|almalinux|ol|oraclelinux)
                            DISTROBASE_LOCAL="rhel"
                            ;;
                        arch|manjaro|endeavouros|garuda)
                            DISTROBASE_LOCAL="arch"
                            ;;
                        opensuse*|suse|sles)
                            DISTROBASE_LOCAL="suse"
                            ;;
                        gentoo)
                            DISTROBASE_LOCAL="gentoo"
                            ;;
                        alpine)
                            DISTROBASE_LOCAL="alpine"
                            ;;
                        void)
                            DISTROBASE_LOCAL="void"
                            ;;
                        *)
                            # Check ID_LIKE for derivatives
                            if [[ -n "${ID_LIKE:-}" ]]; then
                                case "$ID_LIKE" in
                                    *debian*|*ubuntu*)
                                        DISTROBASE_LOCAL="debian"
                                        ;;
                                    *rhel*|*fedora*|*centos*)
                                        DISTROBASE_LOCAL="rhel"
                                        ;;
                                    *arch*)
                                        DISTROBASE_LOCAL="arch"
                                        ;;
                                    *suse*)
                                        DISTROBASE_LOCAL="suse"
                                        ;;
                                    *)
                                        DISTROBASE_LOCAL="linux"
                                        ;;
                                esac
                            else
                                DISTROBASE_LOCAL="linux"
                            fi
                            ;;
                    esac
                else
                    # Legacy detection
                    if [[ -f /etc/debian_version ]]; then
                        DISTROBASE_LOCAL="debian"
                    elif [[ -f /etc/redhat-release ]]; then
                        DISTROBASE_LOCAL="rhel"
                    elif [[ -f /etc/arch-release ]]; then
                        DISTROBASE_LOCAL="arch"
                    else
                        DISTROBASE_LOCAL="linux"
                    fi
                fi
                ;;
            darwin*)
                DISTROBASE_LOCAL="macos"
                ;;
            freebsd*)
                DISTROBASE_LOCAL="freebsd"
                ;;
            openbsd*)
                DISTROBASE_LOCAL="openbsd"
                ;;
            netbsd*)
                DISTROBASE_LOCAL="netbsd"
                ;;
            sunos*)
                DISTROBASE_LOCAL="solaris"
                ;;
            aix*)
                DISTROBASE_LOCAL="aix"
                ;;
            cygwin*|mingw*|msys*)
                DISTROBASE_LOCAL="windows"
                ;;
            *)
                DISTROBASE_LOCAL="unknown"
                ;;
        esac
    fi
    
    # Normalize to lowercase
    DISTROBASE="$(echo "$DISTROBASE_LOCAL" | tr '[:upper:]' '[:lower:]')"
    export DISTROBASE
    
    # Debug output
    if [[ -n "${DEBUG:-}" ]] || [[ -n "${TRACE_DEBUG:-}" ]]; then
        echo "DEBUG: DISTROBASE_LOCAL='$DISTROBASE_LOCAL', DISTROBASE='$DISTROBASE'" >&2
    fi
    
    # Determine sudo command
    if [[ $EUID -eq 0 ]]; then
        SUDOCMD=""
    else
        SUDOCMD="sudo"
    fi
    export SUDOCMD
    
    # =================================================================================================
    # DISTRO-SPECIFIC CONFIGURATIONS
    # =================================================================================================
    
    case "$DISTROBASE" in
        debian)
            # Debian/Ubuntu/Mint/Pop!_OS and derivatives - apt-based
            p_install() { $SUDOCMD apt-get install -y "$@"; }
            p_remove() { $SUDOCMD apt-get remove -y "$@"; }
            p_uninstall() { $SUDOCMD apt-get remove -y "$@"; }
            p_purge() { $SUDOCMD apt-get purge -y "$@"; }
            p_update() { $SUDOCMD apt-get update; }
            p_upgrade() { $SUDOCMD apt-get update && $SUDOCMD apt-get upgrade -y; }
            p_dist_upgrade() { $SUDOCMD apt-get update && $SUDOCMD apt-get dist-upgrade -y; }
            p_search() { apt-cache search "$@"; }
            p_clean() { $SUDOCMD apt-get autoremove -y && $SUDOCMD apt-get autoclean; }
            p_info() { apt-cache show "$@"; }
            p_list() { dpkg -l "$@"; }
            p_list_installed() { dpkg --get-selections | grep -v deinstall; }
            p_which() { dpkg -S "$@"; }
            ;;
        
        rhel)
            # RHEL/CentOS/Fedora/Rocky/AlmaLinux - dnf/yum-based
            if command_check dnf; then
                p_install() { $SUDOCMD dnf install -y "$@"; }
                p_remove() { $SUDOCMD dnf remove -y "$@"; }
                p_uninstall() { $SUDOCMD dnf remove -y "$@"; }
                p_update() { $SUDOCMD dnf check-update; }
                p_upgrade() { $SUDOCMD dnf upgrade -y "$@"; }
                p_dist_upgrade() { $SUDOCMD dnf distro-sync -y; }
                p_search() { dnf search "$@"; }
                p_clean() { $SUDOCMD dnf autoremove -y && $SUDOCMD dnf clean all; }
                p_info() { dnf info "$@"; }
                p_list() { dnf list "$@"; }
                p_list_installed() { dnf list installed; }
                p_which() { dnf provides "$@"; }
            else
                p_install() { $SUDOCMD yum install -y "$@"; }
                p_remove() { $SUDOCMD yum remove -y "$@"; }
                p_uninstall() { $SUDOCMD yum remove -y "$@"; }
                p_update() { $SUDOCMD yum check-update; }
                p_upgrade() { $SUDOCMD yum update -y "$@"; }
                p_dist_upgrade() { $SUDOCMD yum upgrade -y; }
                p_search() { yum search "$@"; }
                p_clean() { $SUDOCMD yum autoremove -y && $SUDOCMD yum clean all; }
                p_info() { yum info "$@"; }
                p_list() { yum list "$@"; }
                p_list_installed() { yum list installed; }
                p_which() { yum provides "$@"; }
            fi
            ;;
        
        arch)
            # Arch/Manjaro - pacman-based
            p_install() { $SUDOCMD pacman -S --noconfirm "$@"; }
            p_remove() { $SUDOCMD pacman -R --noconfirm "$@"; }
            p_uninstall() { $SUDOCMD pacman -R --noconfirm "$@"; }
            p_purge() { $SUDOCMD pacman -Rns --noconfirm "$@"; }
            p_update() { $SUDOCMD pacman -Sy; }
            p_upgrade() { $SUDOCMD pacman -Syu --noconfirm; }
            p_search() { pacman -Ss "$@"; }
            p_clean() { $SUDOCMD pacman -Sc --noconfirm; }
            p_info() { pacman -Si "$@"; }
            p_list() { pacman -Q "$@"; }
            p_list_installed() { pacman -Q; }
            p_which() { pacman -Qo "$@"; }
            ;;
        
        suse)
            # openSUSE - zypper-based
            p_install() { $SUDOCMD zypper install -y "$@"; }
            p_remove() { $SUDOCMD zypper remove -y "$@"; }
            p_uninstall() { $SUDOCMD zypper remove -y "$@"; }
            p_update() { $SUDOCMD zypper refresh; }
            p_upgrade() { $SUDOCMD zypper update -y; }
            p_dist_upgrade() { $SUDOCMD zypper dist-upgrade -y; }
            p_search() { zypper search "$@"; }
            p_clean() { $SUDOCMD zypper clean -a; }
            p_info() { zypper info "$@"; }
            p_list() { zypper packages "$@"; }
            p_list_installed() { zypper search --installed-only; }
            p_which() { zypper search --provides --match-exact "$@"; }
            ;;
        
        gentoo)
            # Gentoo - emerge-based
            p_install() { $SUDOCMD emerge -av "$@"; }
            p_remove() { $SUDOCMD emerge -C "$@"; }
            p_uninstall() { $SUDOCMD emerge -C "$@"; }
            p_update() { $SUDOCMD emerge --sync; }
            p_upgrade() { $SUDOCMD emerge -uDN @world; }
            p_search() { emerge --search "$@"; }
            p_clean() { $SUDOCMD emerge --depclean; }
            p_info() { emerge --info "$@"; }
            p_list() { qlist -I "$@"; }
            p_list_installed() { qlist -I; }
            p_which() { equery belongs "$@"; }
            ;;
        
        alpine)
            # Alpine Linux - apk-based
            p_install() { $SUDOCMD apk add "$@"; }
            p_remove() { $SUDOCMD apk del "$@"; }
            p_uninstall() { $SUDOCMD apk del "$@"; }
            p_update() { $SUDOCMD apk update; }
            p_upgrade() { $SUDOCMD apk upgrade; }
            p_search() { apk search "$@"; }
            p_clean() { $SUDOCMD apk cache clean; }
            p_info() { apk info "$@"; }
            p_list() { apk list "$@"; }
            p_list_installed() { apk info; }
            p_which() { apk info --who-owns "$@"; }
            ;;
        
        void)
            # Void Linux - xbps-based
            p_install() { $SUDOCMD xbps-install -y "$@"; }
            p_remove() { $SUDOCMD xbps-remove -y "$@"; }
            p_uninstall() { $SUDOCMD xbps-remove -y "$@"; }
            p_update() { $SUDOCMD xbps-install -S; }
            p_upgrade() { $SUDOCMD xbps-install -Su; }
            p_search() { xbps-query -Rs "$@"; }
            p_clean() { $SUDOCMD xbps-remove -O; }
            p_info() { xbps-query -R "$@"; }
            p_list() { xbps-query -l "$@"; }
            p_list_installed() { xbps-query -l; }
            p_which() { xbps-query -o "$@"; }
            ;;
        
        macos)
            # macOS - Homebrew-based
            if command_check brew; then
                p_install() { brew install "$@"; }
                p_remove() { brew uninstall "$@"; }
                p_uninstall() { brew uninstall "$@"; }
                p_update() { brew update; }
                p_upgrade() { brew upgrade "$@"; }
                p_search() { brew search "$@"; }
                p_clean() { brew cleanup; }
                p_info() { brew info "$@"; }
                p_list() { brew list "$@"; }
                p_list_installed() { brew list; }
                p_which() { brew which "$@"; }
            else
                echo "Warning: Homebrew not found. Please install from https://brew.sh" >&2
                return 1
            fi
            ;;
        
        freebsd)
            # FreeBSD - pkg-based
            p_install() { $SUDOCMD pkg install -y "$@"; }
            p_remove() { $SUDOCMD pkg delete -y "$@"; }
            p_uninstall() { $SUDOCMD pkg delete -y "$@"; }
            p_update() { $SUDOCMD pkg update; }
            p_upgrade() { $SUDOCMD pkg upgrade -y; }
            p_search() { pkg search "$@"; }
            p_clean() { $SUDOCMD pkg clean -y; }
            p_info() { pkg info "$@"; }
            p_list() { pkg info "$@"; }
            p_list_installed() { pkg info; }
            p_which() { pkg which "$@"; }
            ;;
        
        openbsd)
            # OpenBSD - pkg_add-based
            p_install() { $SUDOCMD pkg_add "$@"; }
            p_remove() { $SUDOCMD pkg_delete "$@"; }
            p_uninstall() { $SUDOCMD pkg_delete "$@"; }
            p_update() { $SUDOCMD pkg_add -u; }
            p_upgrade() { $SUDOCMD pkg_add -u; }
            p_search() { pkg_info -Q "$@"; }
            p_clean() { $SUDOCMD pkg_delete -a; }
            p_info() { pkg_info "$@"; }
            p_list() { pkg_info "$@"; }
            p_list_installed() { pkg_info; }
            p_which() { pkg_info -E "$@"; }
            ;;
        
        solaris)
            # Solaris - pkg-based
            p_install() { $SUDOCMD pkg install "$@"; }
            p_remove() { $SUDOCMD pkg uninstall "$@"; }
            p_uninstall() { $SUDOCMD pkg uninstall "$@"; }
            p_update() { $SUDOCMD pkg refresh; }
            p_upgrade() { $SUDOCMD pkg update; }
            p_search() { pkg search "$@"; }
            p_info() { pkg info "$@"; }
            p_list() { pkg list "$@"; }
            p_list_installed() { pkg list; }
            ;;
        
        windows)
            # Windows/Cygwin - suggest package managers
            echo "Warning: Windows detected. Consider using:" >&2
            echo "  - Chocolatey (https://chocolatey.org/)" >&2
            echo "  - Scoop (https://scoop.sh/)" >&2
            echo "  - winget (built into Windows 11)" >&2
            return 1
            ;;
        
        *)
            # Unknown/unsupported
            echo "Warning: Unknown or unsupported OS/distro: $DISTROBASE" >&2
            echo "Package management functions not configured." >&2
            return 1
            ;;
    esac
    
    # =================================================================================================
    # EXPORT FUNCTIONS
    # =================================================================================================
    export -f p_install p_remove p_uninstall p_update p_upgrade p_search p_clean p_info 2>/dev/null || true
    export -f p_list p_list_installed p_which 2>/dev/null || true
    
    # Optional exports (not all distros have these)
    export -f p_purge 2>/dev/null || true
    export -f p_dist_upgrade 2>/dev/null || true
    
    # =================================================================================================
    # OPTIONAL: CREATE SHORT ALIASES
    # =================================================================================================
    # Uncomment if you want short aliases like 'install', 'remove', etc.
    # NOTE: Be careful with generic names that might conflict with system commands
    
    if [[ "${ENABLE_SHORT_ALIASES:-0}" == "1" ]]; then
        alias install='p_install'
        alias remove='p_remove'
        alias uninstall='p_uninstall'
        alias update='p_update'
        alias upgrade='p_upgrade'
        alias search='p_search'
        alias clean='p_clean'
        alias info='p_info'
    fi
    
    echo "Package functions configured for $DISTROBASE"
}

# =================================================================================================
# AUTO-INITIALIZATION
# =================================================================================================
# Auto-init ONLY in interactive shells
# Scripts like RunMe.sh will call set_package_aliases() manually
if [[ $- == *i* ]]; then
    set_package_aliases
fi

# Export the main function so it's available everywhere
export -f set_package_aliases
export -f command_check