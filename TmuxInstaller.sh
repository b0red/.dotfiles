#!/usr/bin/env bash
################################################################################
#	Installer for .tmux
#	Assumes ~/.tmux repo is already cloned
#
#    - Creates symlink for ~/.tmux.conf
#    - Installs TPM (Tmux Plugin Manager)
#    - Verifies installation
#
################################################################################

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# =============================================================================
# VARIABLES
# =============================================================================
TMUX_DIR="$HOME/.tmux"
TMUX_CONF_LINK="$HOME/.tmux.conf"
TMUX_CONF_TARGET="$HOME/.tmux/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"
TPM_REPO="https://github.com/tmux-plugins/tpm"
INSTALLED_MARKER="$TMUX_DIR/.installed-by-runme"

# =============================================================================
# CHECK IF RUNME.SH ALREADY INSTALLED TMUX
# =============================================================================
if [ -f "$INSTALLED_MARKER" ]; then
    install_date=$(cat "$INSTALLED_MARKER" 2>/dev/null || echo "unknown date")
    echo ""
    echo "========================================="
    echo "⚠️  RunMe.sh Already Set Up Tmux"
    echo "========================================="
    echo "RunMe.sh installed tmux on: $install_date"
    echo ""
    echo "This means:"
    echo "  • ~/.tmux repo is already cloned"
    echo "  • Submodules may already be initialized"
    echo "  • Symlinks may already be created"
    echo ""
    read -rp "Do you want to run this installer anyway? ([y]es or [N]o): " reply
    case $(echo "$reply" | tr '[:upper:]' '[:lower:]') in
        y|yes)
            echo ""
            echo "✓ Proceeding with installation..."
            echo "  (This may overwrite existing configuration)"
            echo ""
            sleep 2
            ;;
        *)
            echo ""
            echo "✓ Exiting. Your existing tmux setup remains unchanged."
            echo ""
            exit 0
            ;;
    esac
fi

# =============================================================================
# INSTALLATION BEGINS
# =============================================================================
clear
echo -e "This script configures tmux after the repo has been cloned.\n"

# =============================================================================
# FUNCTIONS
# =============================================================================

ask_yes_or_no() {
    local prompt="$1"
    local reply
    read -rp "$prompt ([y]es or [N]o): " reply
    case $(echo "$reply" | tr '[:upper:]' '[:lower:]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

is_it_installed() {
    local installed=0
    local missing=0
    local progs=("$@")
    
    for p in "${progs[@]}"; do
        if command -v "$p" &>/dev/null; then
            echo "✓ $p is installed"
            ((installed++))
        else
            echo "❌ '$p' is not installed. Do you want to install '$p'?"
            if [[ "yes" == $(ask_yes_or_no "Are you sure?") ]]; then
                echo "Installing $p..."
                
                # Detect package manager and install
                if command -v apt-get &>/dev/null; then
                    sudo apt-get install -y "$p" || {
                        echo "❌ Failed to install $p with apt-get"
                        ((missing++))
                        continue
                    }
                elif command -v dnf &>/dev/null; then
                    sudo dnf install -y "$p" || {
                        echo "❌ Failed to install $p with dnf"
                        ((missing++))
                        continue
                    }
                elif command -v yum &>/dev/null; then
                    sudo yum install -y "$p" || {
                        echo "❌ Failed to install $p with yum"
                        ((missing++))
                        continue
                    }
                elif command -v pacman &>/dev/null; then
                    sudo pacman -S --noconfirm "$p" || {
                        echo "❌ Failed to install $p with pacman"
                        ((missing++))
                        continue
                    }
                elif command -v zypper &>/dev/null; then
                    sudo zypper install -y "$p" || {
                        echo "❌ Failed to install $p with zypper"
                        ((missing++))
                        continue
                    }
                elif command -v brew &>/dev/null; then
                    brew install "$p" || {
                        echo "❌ Failed to install $p with brew"
                        ((missing++))
                        continue
                    }
                else
                    echo "❌ No supported package manager found"
                    ((missing++))
                    continue
                fi
                
                ((installed++))
            else
                echo "⚠️  Skipped installation of: '$p'"
                ((missing++))
            fi
        fi
    done
    
    echo ""
    echo "Summary: $installed installed, $missing skipped"
    
    if [ $missing -gt 0 ]; then
        echo "⚠️  Warning: Some required software is missing"
        return 1
    fi
    return 0
}

clone_tpm_plugin() {
    echo ""
    echo "========================================="
    echo "Installing TPM (Tmux Plugin Manager)"
    echo "========================================="
    
    # Check if TPM is already installed
    if [ -d "$TPM_DIR/.git" ]; then
        echo "✓ TPM already installed at: $TPM_DIR"
        echo ""
        read -rp "Update TPM to latest version? ([y]es or [N]o): " reply
        case $(echo "$reply" | tr '[:upper:]' '[:lower:]') in
            y|yes)
                echo "Updating TPM..."
                if git -C "$TPM_DIR" pull 2>&1; then
                    echo "✓ TPM updated successfully"
                else
                    echo "❌ Failed to update TPM"
                    return 1
                fi
                ;;
            *)
                echo "⚠️  Skipping TPM update"
                ;;
        esac
        return 0
    elif [ -e "$TPM_DIR" ]; then
        echo "⚠️  Warning: $TPM_DIR exists but is not a git repository"
        read -rp "Remove and reinstall TPM? ([y]es or [N]o): " reply
        case $(echo "$reply" | tr '[:upper:]' '[:lower:]') in
            y|yes)
                echo "Removing existing directory..."
                if rm -rf "$TPM_DIR"; then
                    echo "✓ Removed existing directory"
                else
                    echo "❌ Failed to remove directory"
                    return 1
                fi
                ;;
            *)
                echo "⚠️  Skipping TPM installation"
                return 1
                ;;
        esac
    fi
    
    # Create plugins directory if it doesn't exist
    if ! mkdir -p "$HOME/.tmux/plugins" 2>/dev/null; then
        echo "❌ Failed to create plugins directory"
        return 1
    fi
    
    # Clone TPM
    echo "Cloning TPM from: $TPM_REPO"
    if GIT_TERMINAL_PROMPT=0 git clone --depth=1 "$TPM_REPO" "$TPM_DIR" 2>&1; then
        echo "✓ TPM installed successfully to: $TPM_DIR"
        echo ""
        echo "TPM Installation Notes:"
        echo "  • Press prefix + I (capital i) in tmux to install plugins"
        echo "  • Press prefix + U to update plugins"
        echo "  • Press prefix + alt + u to uninstall plugins"
        return 0
    else
        echo "❌ Failed to clone TPM"
        echo "  Repository: $TPM_REPO"
        echo "  Target: $TPM_DIR"
        return 1
    fi
}

# =============================================================================
# CHECK DEPENDENCIES
# =============================================================================
echo "Checking dependencies..."
if ! is_it_installed git tmux; then
    echo "❌ Required software missing. Exiting."
    exit 1
fi

# =============================================================================
# CHECK IF REPO EXISTS
# =============================================================================
if [ ! -d "$TMUX_DIR" ]; then
    echo ""
    echo "❌ Error: ~/.tmux directory not found!"
    echo ""
    echo "Please clone the repository first:"
    echo "  git clone git@bitbucket.org:b0red/tmux.git ~/.tmux"
    echo ""
    echo "Or run RunMe.sh which handles this automatically."
    exit 1
fi

if [ ! -d "$TMUX_DIR/.git" ]; then
    echo "⚠️  Warning: ~/.tmux exists but is not a git repository"
    read -rp "Continue anyway? ([y]es or [N]o): " reply
    case $(echo "$reply" | tr '[:upper:]' '[:lower:]') in
        y|yes) ;;
        *) echo "Exiting."; exit 0 ;;
    esac
fi

echo "✓ Found ~/.tmux repository"

# =============================================================================
# CREATE SYMLINK
# =============================================================================
echo ""
echo "Creating symlink for .tmux.conf..."

# Check if target file exists
if [ ! -f "$TMUX_CONF_TARGET" ]; then
    echo "❌ Error: $TMUX_CONF_TARGET not found in repository"
    exit 1
fi

# Handle existing file/symlink
if [ -L "$TMUX_CONF_LINK" ]; then
    if [ -e "$TMUX_CONF_LINK" ]; then
        echo "  • Found existing symlink, removing..."
        if rm -f "$TMUX_CONF_LINK"; then
            echo "    ✓ Removed old symlink"
        else
            echo "    ❌ Failed to remove old symlink"
            exit 1
        fi
    else
        echo "  • Found broken symlink, removing..."
        if rm -f "$TMUX_CONF_LINK"; then
            echo "    ✓ Removed broken symlink"
        else
            echo "    ❌ Failed to remove broken symlink"
            exit 1
        fi
    fi
elif [ -e "$TMUX_CONF_LINK" ]; then
    backup_name="${TMUX_CONF_LINK}.backup-$(date +%Y%m%d-%H%M%S)"
    echo "  • Found existing file (not a symlink)"
    echo "  • Backing up to: $backup_name"
    if mv "$TMUX_CONF_LINK" "$backup_name"; then
        echo "    ✓ Backup created"
    else
        echo "    ❌ Failed to create backup"
        exit 1
    fi
fi

# Create the symlink
if ln -s "$TMUX_CONF_TARGET" "$TMUX_CONF_LINK"; then
    echo "✓ Created symlink: $TMUX_CONF_LINK -> $TMUX_CONF_TARGET"
else
    echo "❌ Failed to create symlink"
    exit 1
fi

# =============================================================================
# INSTALL TPM (TMUX PLUGIN MANAGER)
# =============================================================================
if ! clone_tpm_plugin; then
    echo "⚠️  Warning: TPM installation failed or was skipped"
    echo "You can install it manually later with:"
    echo "  git clone $TPM_REPO $TPM_DIR"
fi

# =============================================================================
# VERIFY TMUX CONFIGURATION
# =============================================================================
echo ""
echo "========================================="
echo "Verifying Configuration"
echo "========================================="

# Check if tmux can parse the config
if command -v tmux &>/dev/null; then
    if tmux -f "$TMUX_CONF_LINK" list-keys >/dev/null 2>&1; then
        echo "✓ Tmux configuration is valid"
    else
        echo "⚠️  Warning: Tmux configuration may have errors"
        echo "  Run 'tmux -f ~/.tmux.conf list-keys' to check"
    fi
else
    echo "⚠️  Tmux not found, skipping config validation"
fi

# Verify symlink
if [ -L "$TMUX_CONF_LINK" ] && [ -e "$TMUX_CONF_LINK" ]; then
    actual_target=$(readlink -f "$TMUX_CONF_LINK" 2>/dev/null || readlink "$TMUX_CONF_LINK")
    expected_target=$(readlink -f "$TMUX_CONF_TARGET" 2>/dev/null || echo "$TMUX_CONF_TARGET")
    
    if [ "$actual_target" = "$expected_target" ]; then
        echo "✓ Symlink verified: points to correct target"
    else
        echo "⚠️  Warning: Symlink points to unexpected location"
        echo "  Expected: $expected_target"
        echo "  Actual: $actual_target"
    fi
else
    echo "❌ Symlink verification failed"
fi

# Check TPM installation
if [ -d "$TPM_DIR/.git" ]; then
    echo "✓ TPM installed at: $TPM_DIR"
else
    echo "⚠️  TPM not installed or incomplete"
fi

# =============================================================================
# COMPLETION
# =============================================================================
echo ""
echo "========================================="
echo "✓ Tmux Installation Complete!"
echo "========================================="
echo ""
echo "Configuration:"
echo "  • Symlink created: ~/.tmux.conf"
echo "  • Repository: ~/.tmux"
if [ -d "$TPM_DIR/.git" ]; then
    echo "  • TPM installed: $TPM_DIR"
fi
echo ""
echo "Next steps:"
echo "  1. Start tmux: tmux"
echo "  2. Reload config in existing session: tmux source ~/.tmux.conf"
if [ -d "$TPM_DIR/.git" ]; then
    echo "  3. Install plugins: Press prefix + I (capital i)"
    echo "  4. Check plugins: ls ~/.tmux/plugins/"
else
    echo "  3. Install TPM manually if needed"
fi
echo "  5. Check status: tmux list-sessions"
echo ""
echo "Troubleshooting:"
echo "  • Config validation: tmux -f ~/.tmux.conf list-keys"
echo "  • Kill all sessions: tmux kill-server"
echo "  • Start fresh: tmux new-session"
echo ""
echo "========================================="
exit 0