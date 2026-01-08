# ~/dotfiles/.bashrc.d/pkg_aliases.bash
# Cross-distro package manager aliases

set_package_aliases() {
    local DISTRO_BASE_LOCAL

    # Prefer cached value
    if [ -n "${DISTRO_BASE:-}" ]; then
        DISTRO_BASE_LOCAL="$DISTRO_BASE"
    else
        if [ -f /etc/os-release ]; then
            # shellcheck disable=SC1091
            . /etc/os-release
            DISTRO_BASE_LOCAL="${ID_LIKE:-$ID}"
        else
            DISTRO_BASE_LOCAL=$(uname -s | tr '[:upper:]' '[:lower:]')
        fi
        DISTRO_BASE="${DISTRO_BASE_LOCAL,,}"
        export DISTRO_BASE
    fi

    case "$DISTRO_BASE_LOCAL" in
        debian*|ubuntu*)
            alias install='sudo apt-get install -y'
            alias remove='sudo apt-get remove -y'
            alias uninstall='sudo apt-get remove -y'
            alias update='sudo apt-get update && sudo apt-get upgrade -y'
            ;;
        redhat*|centos*|fedora*|almalinux*|rocky*|rhel*)
            if command -v dnf >/dev/null 2>&1; then
                alias install='sudo dnf install -y'
                alias remove='sudo dnf remove -y'
                alias uninstall='sudo dnf remove -y'
                alias update='sudo dnf upgrade -y'
            else
                alias install='sudo yum install -y'
                alias remove='sudo yum remove -y'
                alias uninstall='sudo yum remove -y'
                alias update='sudo yum update -y'
            fi
            ;;
        opensuse*|suse*)
            alias install='sudo zypper install -y'
            alias remove='sudo zypper remove -y'
            alias uninstall='sudo zypper remove -y'
            alias update='sudo zypper update -y'
            ;;
        arch*|manjaro*)
            alias install='sudo pacman -S --noconfirm'
            alias remove='sudo pacman -Rns --noconfirm'
            alias uninstall='sudo pacman -Rns --noconfirm'
            alias update='sudo pacman -Syu --noconfirm'
            ;;
        gentoo*)
            alias install='sudo emerge -av'
            alias remove='sudo emerge --unmerge'
            alias uninstall='sudo emerge --unmerge'
            alias update='sudo emerge --update --deep @world'
            ;;
        freebsd*)
            alias install='sudo pkg install -y'
            alias remove='sudo pkg delete -y'
            alias uninstall='sudo pkg delete -y'
            alias update='sudo pkg upgrade -y'
            ;;
        *)
            # No-op but not fatal
            return 0
            ;;
    esac
    # log "Aliases set for $DISTRO_BASE: install, remove, update"
    # # Reload aliases immediately for current session (first-run fix)
    # source /dev/stdin <<< "$(alias | grep 'alias install\|alias {remove,uninstall}\|alias update')"

    # # Make sure aliases expand in functions
    # shopt -s expand_aliases
}
