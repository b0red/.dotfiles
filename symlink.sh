#!/usr/bin/env bash

# symlink.sh - Distro-specific profile symlink management
# Called from run_me_first.sh with distro information as arguments

set -euo pipefail

# Accept distro info from command line
DISTRO="${1:-unknown}"
DISTRO_BASE="${2:-unknown}"

# Resolve repository directory (the directory of this script)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Symlink helper function with backup if target file exists
linkwork() {
    local linkTocheck="$1"
    local sourceLink="$2"
    
    # Backup existing file (not symlink)
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
        echo "✓ Created: $linkTocheck -> $sourceLink"
        return 0
    else
        echo "❌ Failed: $linkTocheck" >&2
        return 1
    fi
}

# Only run on Linux
if [ "$(uname -s)" != "Linux" ]; then
    echo "⚠️ Not Linux, skipping distro-specific symlinks"
    exit 0
fi

home_dir="$HOME"

# Distro-specific profile symlinking
case "$DISTRO" in
    kali)
        echo "Setting up Kali-specific profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.kali_profile" "$REPO_DIR/.kali_profile"
        #linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
        #linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
        ;;
    
    raspbian)
        echo "Setting up Raspbian-specific profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.rpi_profile" "$REPO_DIR/.rpi_profile"
        #linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
        #linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
        ;;
    
    ubuntu)
        echo "Setting up Ubuntu-specific profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.ubu_profile" "$REPO_DIR/.ubu_profile"
        #linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
        #linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
        ;;
    
    centos|rhel|fedora)
        echo "Setting up RHEL-based profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        linkwork "$home_dir/.centos_profile" "$REPO_DIR/.centos_profile"
        #linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
        #linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
        ;;
    
    *)
        echo "Setting up default Linux profiles..."
        linkwork "$home_dir/.common_profile" "$REPO_DIR/.common_profile"
        #linkwork "$home_dir/.bashrc" "$REPO_DIR/.bashrc"
        #linkwork "$home_dir/.gitconfig" "$REPO_DIR/.gitconfig"
        ;;
esac

echo "✓ Distro-specific symlinks complete"
