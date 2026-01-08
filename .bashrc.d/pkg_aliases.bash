# ~/dotfiles/.bashrc.d/pkg_aliases.bash
# Cross-distro package manager functions

set_package_aliases() {
    local DISTRO_BASE_LOCAL
    local SUDO_CMD

    # Detect sudo/doas availability (FreeBSD, OpenBSD use doas)
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
    elif command -v doas >/dev/null 2>&1; then
        SUDO_CMD="doas"
    else
        SUDO_CMD=""  # Run without elevation (will fail if needed)
    fi

    # Prefer cached value, otherwise detect
    if [ -n "${DISTRO_BASE:-}" ]; then
        DISTRO_BASE_LOCAL="$DISTRO_BASE"
    else
        if [ -f /etc/os-release ]; then
            # shellcheck disable=SC1091
            . /etc/os-release
            DISTRO_BASE_LOCAL="${ID_LIKE:-$ID}"
        elif [ "$(uname -s)" = "Darwin" ]; then
            DISTRO_BASE_LOCAL="macos"
        else
            DISTRO_BASE_LOCAL=$(uname -s | tr '[:upper:]' '[:lower:]')
        fi
        # Export for future use (lowercase for consistency)
        DISTRO_BASE=$(echo "$DISTRO_BASE_LOCAL" | tr '[:upper:]' '[:lower:]')
        export DISTRO_BASE
    fi

    case "$DISTRO_BASE_LOCAL" in
        debian*|ubuntu*|linuxmint*|pop*)
            install() { $SUDO_CMD apt-get install -y "$@"; }
            remove() { $SUDO_CMD apt-get remove -y "$@"; }
            uninstall() { $SUDO_CMD apt-get remove -y "$@"; }
            update() { $SUDO_CMD apt-get update; }
            upgrade() { $SUDO_CMD apt-get update && $SUDO_CMD apt-get upgrade -y; }
            search() { apt-cache search "$@"; }
            clean() { $SUDO_CMD apt-get autoremove -y && $SUDO_CMD apt-get autoclean; }
            info() { apt-cache show "$@"; }
            ;;
        
        redhat*|centos*|fedora*|almalinux*|rocky*|rhel*)
            if command -v dnf >/dev/null 2>&1; then
                install() { $SUDO_CMD dnf install -y "$@"; }
                remove() { $SUDO_CMD dnf remove -y "$@"; }
                uninstall() { $SUDO_CMD dnf remove -y "$@"; }
                update() { $SUDO_CMD dnf check-update; }
                upgrade() { $SUDO_CMD dnf upgrade -y; }
                search() { dnf search "$@"; }
                clean() { $SUDO_CMD dnf autoremove -y && $SUDO_CMD dnf clean all; }
                info() { dnf info "$@"; }
            else
                install() { $SUDO_CMD yum install -y "$@"; }
                remove() { $SUDO_CMD yum remove -y "$@"; }
                uninstall() { $SUDO_CMD yum remove -y "$@"; }
                update() { $SUDO_CMD yum check-update; }
                upgrade() { $SUDO_CMD yum update -y; }
                search() { yum search "$@"; }
                clean() { $SUDO_CMD yum autoremove -y && $SUDO_CMD yum clean all; }
                info() { yum info "$@"; }
            fi
            ;;
        
        opensuse*|suse*|sles*)
            install() { $SUDO_CMD zypper install -y "$@"; }
            remove() { $SUDO_CMD zypper remove -y "$@"; }
            uninstall() { $SUDO_CMD zypper remove -y "$@"; }
            update() { $SUDO_CMD zypper refresh; }
            upgrade() { $SUDO_CMD zypper update -y; }
            search() { zypper search "$@"; }
            clean() { $SUDO_CMD zypper clean -a; }
            info() { zypper info "$@"; }
            ;;
        
        arch*|manjaro*|endeavouros*)
            install() { $SUDO_CMD pacman -S --noconfirm "$@"; }
            remove() { $SUDO_CMD pacman -Rns --noconfirm "$@"; }
            uninstall() { $SUDO_CMD pacman -Rns --noconfirm "$@"; }
            update() { $SUDO_CMD pacman -Sy; }
            upgrade() { $SUDO_CMD pacman -Syu --noconfirm; }
            search() { pacman -Ss "$@"; }
            clean() { $SUDO_CMD pacman -Sc --noconfirm; }
            info() { pacman -Si "$@"; }
            ;;
        
        gentoo*)
            install() { $SUDO_CMD emerge -av "$@"; }
            remove() { $SUDO_CMD emerge --unmerge "$@"; }
            uninstall() { $SUDO_CMD emerge --unmerge "$@"; }
            update() { $SUDO_CMD emerge --sync; }
            upgrade() { $SUDO_CMD emerge --update --deep --newuse @world; }
            search() { emerge --search "$@"; }
            clean() { $SUDO_CMD emerge --depclean; }
            info() { emerge --info "$@"; }
            ;;
        
        alpine*)
            install() { $SUDO_CMD apk add "$@"; }
            remove() { $SUDO_CMD apk del "$@"; }
            uninstall() { $SUDO_CMD apk del "$@"; }
            update() { $SUDO_CMD apk update; }
            upgrade() { $SUDO_CMD apk upgrade; }
            search() { apk search "$@"; }
            clean() { $SUDO_CMD apk cache clean; }
            info() { apk info "$@"; }
            ;;
        
        void*)
            install() { $SUDO_CMD xbps-install -y "$@"; }
            remove() { $SUDO_CMD xbps-remove -y "$@"; }
            uninstall() { $SUDO_CMD xbps-remove -y "$@"; }
            update() { $SUDO_CMD xbps-install -S; }
            upgrade() { $SUDO_CMD xbps-install -Su; }
            search() { xbps-query -Rs "$@"; }
            clean() { $SUDO_CMD xbps-remove -yo; }
            info() { xbps-query -R "$@"; }
            ;;
        
        nixos*|nix*)
            install() { nix-env -iA "$@"; }
            remove() { nix-env -e "$@"; }
            uninstall() { nix-env -e "$@"; }
            update() { nix-channel --update; }
            upgrade() { nix-env -u; }
            search() { nix search nixpkgs "$@"; }
            clean() { nix-collect-garbage -d; }
            info() { nix-env -qa --description "$@"; }
            ;;
        
        freebsd*)
            install() { $SUDO_CMD pkg install -y "$@"; }
            remove() { $SUDO_CMD pkg delete -y "$@"; }
            uninstall() { $SUDO_CMD pkg delete -y "$@"; }
            update() { $SUDO_CMD pkg update; }
            upgrade() { $SUDO_CMD pkg upgrade -y; }
            search() { pkg search "$@"; }
            clean() { $SUDO_CMD pkg autoremove -y && $SUDO_CMD pkg clean -y; }
            info() { pkg info "$@"; }
            ;;
        
        openbsd*)
            install() { $SUDO_CMD pkg_add "$@"; }
            remove() { $SUDO_CMD pkg_delete "$@"; }
            uninstall() { $SUDO_CMD pkg_delete "$@"; }
            update() { $SUDO_CMD pkg_add -u; }
            upgrade() { $SUDO_CMD pkg_add -u; }
            search() { pkg_info -Q "$@"; }
            clean() { $SUDO_CMD pkg_delete -a; }
            info() { pkg_info "$@"; }
            ;;
        
        macos*|darwin*)
            if command -v brew >/dev/null 2>&1; then
                install() { brew install "$@"; }
                remove() { brew uninstall "$@"; }
                uninstall() { brew uninstall "$@"; }
                update() { brew update; }
                upgrade() { brew upgrade; }
                search() { brew search "$@"; }
                clean() { brew cleanup; }
                info() { brew info "$@"; }
            else
                echo "⚠️  Homebrew not installed. Install from: https://brew.sh"
                return 1
            fi
            ;;
        
        *)
            echo "⚠️  Unknown OS: $DISTRO_BASE_LOCAL"
            echo "Package manager functions not configured."
            echo "Supported: Debian, Ubuntu, RHEL, Fedora, Arch, Gentoo, Alpine, Void, NixOS, FreeBSD, OpenBSD, macOS"
            return 1
            ;;
    esac

    # Set up version command (fastfetch or neofetch)
    if command -v fastfetch >/dev/null 2>&1; then
        alias version="fastfetch"
    elif command -v neofetch >/dev/null 2>&1; then
        alias version="neofetch"
    else
        version() {
            echo "⚠️  'version' command not found. Install neofetch or fastfetch?"
            read -r -p "Install (n)eofetch, (f)astfetch, or (c)ancel? [n/f/c]: " choice
            case "$choice" in
                n|N)
                    echo "Installing neofetch..."
                    install neofetch && neofetch
                    ;;
                f|F)
                    echo "Installing fastfetch..."
                    install fastfetch && fastfetch
                    ;;
                *)
                    echo "Installation cancelled."
                    ;;
            esac
        }
    fi

    echo "✓ Package functions configured for: $DISTRO_BASE_LOCAL"
}