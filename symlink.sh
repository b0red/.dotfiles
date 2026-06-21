#!/usr/bin/env bash

# symlink.sh - Distro-specific profile symlink management
# Called from run_me_first.sh with distro information as arguments

set -euo pipefail

# Accept distro info from command line
DISTRO="${1:-unknown}"

# Resolve repository directory (the directory of this script)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Symlink helper — skips gracefully if source file not in repo yet
linkwork() {
    local linkTocheck="$1"
    local sourceLink="$2"

    # Skip if source doesn't exist in repo (file is planned but not yet added)
    if [ ! -e "$sourceLink" ]; then
        echo "⏭  Skipping (not in repo): $(basename "$sourceLink")"
        return 0
    fi

    # Backup existing regular file (not a symlink)
    if [ -f "$linkTocheck" ] && [ ! -L "$linkTocheck" ]; then
        echo "Backing up: $linkTocheck"
        mv "$linkTocheck" "$linkTocheck.bak-$(date +%Y%m%d_%H%M%S)"
    fi

    # Remove existing symlink or file
    if [ -e "$linkTocheck" ] || [ -L "$linkTocheck" ]; then
        rm -f "$linkTocheck"
    fi

    # Create symlink
    if ln -s "$sourceLink" "$linkTocheck"; then
        echo "✓ Linked: $(basename "$linkTocheck") -> $sourceLink"
        return 0
    else
        echo "❌ Failed: $linkTocheck" >&2
        return 1
    fi
}

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
    echo "⚠️  Not Linux, skipping distro-specific symlinks"
    exit 0
fi

home_dir="$HOME"

# Distro-specific profile symlinking.
# Each case links a .common_profile (shared across all *nix) and a
# distro-specific profile file. Both may be absent if not yet written
# to the repo — linkwork() skips silently in that case.
case "$DISTRO" in
    kali)
        echo "Setting up Kali-specific profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.kali_profile"   "$REPO_DIR/.kali_profile"
        ;;

    raspbian|raspios)
        echo "Setting up Raspberry Pi OS profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.rpi_profile"    "$REPO_DIR/.rpi_profile"
        ;;

    ubuntu)
        echo "Setting up Ubuntu profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.ubu_profile"    "$REPO_DIR/.ubu_profile"
        ;;

    debian)
        echo "Setting up Debian profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.deb_profile"    "$REPO_DIR/.deb_profile"
        ;;

    fedora)
        echo "Setting up Fedora profiles..."
        linkwork "$home_dir/.common_profile"    "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.fedora_profile"    "$REPO_DIR/.fedora_profile"
        ;;

    centos|rhel|rocky|almalinux)
        echo "Setting up RHEL-based profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.rhel_profile"   "$REPO_DIR/.rhel_profile"
        ;;

    arch|manjaro|endeavouros)
        echo "Setting up Arch-based profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.arch_profile"   "$REPO_DIR/.arch_profile"
        ;;

    opensuse*|sles)
        echo "Setting up openSUSE profiles..."
        linkwork "$home_dir/.common_profile"  "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.suse_profile"    "$REPO_DIR/.suse_profile"
        ;;

    *)
        echo "Setting up default Linux profiles (distro: $DISTRO)..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        ;;
esac

echo "✓ Distro-specific symlinks complete"
