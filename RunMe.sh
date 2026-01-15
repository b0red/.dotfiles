#!/usr/bin/env bash
# RunMe.sh - Dotfiles installer for first-run setup on new systems
# Backs up old files, symlinks dotfiles, installs apps, updates submodules.

set -euo pipefail

# Clear all aliases to avoid conflicts
unalias -a 2>/dev/null

# =============================================================================
# RECURSION GUARD
# =============================================================================
if [ -n "${RUNME_INITIATED:-}" ]; then
    echo "RunMe.sh already running (PID $$)" >&2
    exit 1
fi
RUNME_INITIATED=1
export RUNME_INITIATED

# =============================================================================
# CONFIGURATION
# =============================================================================
DEBUG=${DEBUG:-0}
TRACE_DEBUG=${TRACE_DEBUG:-0}
SLEEP=${SLEEP:-2}
DIR="$HOME/dotfiles"
OLD_FILES="$DIR/oldfiles"
LOG_DIR="$DIR/logs"
# Old log dir
# LOG_DIR="$DIR/logs/install-$(date +%Y-%m-%d).log"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
TITLE="Dotfiles Installer Script"
# APP_ARRAY=(curl htop ncdu pydf tree tmux vim mc fd-find git bat tldr jq wget unzip zip broot atop btop fzf yq entr)
DOT_ARRAY=("$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.inputrc")
OLD_FILE_ARRAY=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.inputrc" "$HOME/.cshrc" "$HOME/.login")

# ANSI Color for Yellow
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variable for sudo keeper process
SUDO_KEEPER_PID=""

# =============================================================================
# MAIN FUNCTION
# =============================================================================
main() {
    logfile_init
    log "========================================="
    log "Starting Dotfiles Installation"
    log "========================================="
    # CHANGES: Enable trace here so `--trace` passed on the command line
    # can turn on `set -x` before the bulk of installation work runs.
    if [ "${TRACE_DEBUG:-0}" -eq 1 ]; then
        set -x
        trap 'read -p "DEBUG: Press Enter..."' DEBUG
        log "✓ Trace enabled"
    fi
    
    get_os_info
    load_package_functions || log "⚠️ Continuing without package functions"
    load_app_list || log "⚠️ Using fallback app list"  # ADD THIS LINE
    
    # Prompt for sudo early to avoid interruption during installation
    log ""
    log "🔐 Checking sudo access (you may be prompted for password)..."
    if ! sudo -v; then
        log "❌ Sudo access required for package installation"
        log "Run 'sudo -v' to verify sudo access, then try again."
        exit 1
    fi
    log "✓ Sudo access verified"
    
    # Keep sudo alive in background
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_KEEPER_PID=$!
    log "✓ Sudo session refreshed (will stay active during installation)"
    log ""
    
    backup_dotfiles
    cleanup_symlinks
    symlink_dotfiles "$DISTRO" "$DISTRO_BASE"  # ADD PARAMETERS
    install_apps
    archive_backup
    update_submodules
    clone_repos
    symlink_external_repos
    # add_tmux_line
    source_bashrc
    
    log ""
    log "========================================="
    log "✓ Installation Complete!"
    log "========================================="
    log "Log saved to: $LOG"
    log ""
    log "Next steps:"
    log "  1. Restart your shell: exec bash"
    log "  2. Or source manually: source ~/.bashrc"
    log "  3. Test package functions: version"
    log "  4. Check for warnings above"
    log ""
    log "For troubleshooting, see: README.md"
    log "To revert changes: ./RunMe.sh --revert"
    log "========================================="
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Logging function, prints to both log file and stdout cleanly
log() {
    local msg="$1"
    # 1. Write timestamped message to log file only
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG" 2>/dev/null
    
    # 2. Print clean message to screen (stdout)
    echo -e "$msg"
}

logfile_init() {
    mkdir -p "$LOG_DIR"
    LOG="$LOG_DIR/install-$DATE.log"
    if [ -t 1 ]; then
        exec > >(tee -a "$LOG")
        exec 2>&1
    fi
    log "$TITLE started (PID $$)"
}

check_or_add_line() {
    local line="$1" file="$2"
    
    # Don't modify symlinked files (they point to repo)
    if [ -L "$file" ]; then
        log "⚠️  Skipping $file (symlink to repo)"
        return 0
    fi
    
    if [ ! -f "$file" ]; then
        touch "$file"
        log "Created empty $file"
    fi
    
    if grep -qxF "$line" "$file" 2>/dev/null; then
        log "Line already exists in $file"
    else
        echo "$line" >> "$file"
        log "Added line to $file"
    fi
}

add_file_header() {
    local target_file="$1"
    local creation_date="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="${HOSTNAME:-$(hostname)}"
    
    # Check if header already exists and remove it
    if grep -q "Created by RunMe.sh" "$target_file" 2>/dev/null; then
        log "Updating header in $(basename "$target_file")..."
        
        # Remove old header (first 6 lines if they contain the pattern)
        local temp_file=$(mktemp)
        local skip_lines=0
        
        # Count header lines to skip
        while IFS= read -r line; do
            if [[ "$line" =~ ^###.*-\+- ]] || [[ "$line" =~ ^###.*Created\ by\ RunMe\.sh ]] || \
               [[ "$line" =~ ^###.*Host: ]] || [[ "$line" =~ ^###.*User: ]] || \
               [[ "$line" =~ ^###.*Distro: ]] || [[ "$line" =~ ^$ && $skip_lines -lt 7 ]]; then
                skip_lines=$((skip_lines + 1))
            else
                break
            fi
        done < "$target_file"
        
        # Copy file without old header
        tail -n +$((skip_lines + 1)) "$target_file" > "$temp_file"
        mv "$temp_file" "$target_file"
    else
        log "Adding header to $(basename "$target_file")..."
    fi
    
    # Create new header
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << EOF
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh $creation_date
###                                             Host: $hostname
###                                             User: $USER
###                                             Distro: $DISTRO
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

EOF
    
    # Append existing content
    if [ -f "$target_file" ]; then
        cat "$target_file" >> "$temp_file"
    fi
    
    # Replace original
    if mv "$temp_file" "$target_file"; then
        log "✓ Header updated in $(basename "$target_file")"
        return 0
    else
        log "❌ Failed to update header in $(basename "$target_file")"
        rm -f "$temp_file"
        return 1
    fi
}

cleanup_on_exit() {
    # Kill sudo keeper if running
    if [ -n "$SUDO_KEEPER_PID" ]; then
        kill "$SUDO_KEEPER_PID" 2>/dev/null || true
    fi
}

# =============================================================================
# SYSTEM DETECTION
# =============================================================================

get_os_info() {
    local os kernel mach
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    kernel=$(uname -r)
    mach=$(uname -m)
    
    DISTRO="unknown"
    DISTRO_BASE="unknown"
    
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_BASE="${ID_LIKE:-$ID}"
    fi
    
    export OS="$os" KERNEL="$kernel" MACH="$mach" DISTRO DISTRO_BASE
    log "Detected: OS=$OS, Distro=$DISTRO, Base=$DISTRO_BASE, Kernel=$KERNEL, Arch=$MACH"
}

# =============================================================================
# APPLICATION LIST MANAGEMENT
# =============================================================================

load_app_list() {
    local app_file="$DIR/.install_apps.inc"
    
    if [ ! -r "$app_file" ]; then
        log "⚠️ Warning: $app_file not found"
        log "Using fallback app list"
        # Fallback minimal list
        APP_ARRAY=(curl wget git vim tmux htop)
        return 1
    fi
    
    # Read file, filter comments and empty lines
    local apps=()
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove inline comments (everything after #)
        line="${line%%#*}"
        
        # Trim whitespace
        line=$(echo "$line" | xargs)
        
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Add to array
        apps+=("$line")
    done < "$app_file"
    
    if [ ${#apps[@]} -eq 0 ]; then
        log "⚠️ No apps found in $app_file"
        return 1
    fi
    
    APP_ARRAY=("${apps[@]}")
    log "✓ Loaded ${#APP_ARRAY[@]} applications from $app_file"
    return 0
}

# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

load_package_functions() {
    local pkg_file="$DIR/.bashrc.d/pkg_aliases.bash"
    
    if [ ! -r "$pkg_file" ]; then
        log "⚠️  Warning: $pkg_file not found"
        return 1
    fi
    
    # Source the file to get set_package_aliases function
    # shellcheck disable=SC1090
    if ! . "$pkg_file" 2>/dev/null; then
        log "❌ Failed to source $pkg_file"
        return 1
    fi
    
    # Call the function to set up install/remove/etc functions
    if command -v set_package_aliases >/dev/null 2>&1; then
        if set_package_aliases; then
            log "✓ Package management functions loaded for $DISTRO_BASE"
        else
            log "⚠️  set_package_aliases returned error"
            return 1
        fi
    else
        log "⚠️  set_package_aliases function not found in $pkg_file"
        return 1
    fi
}

install_apps() {
    log "Installing applications..."
    
    # Verify app list is loaded
    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log "❌ APP_ARRAY not loaded or empty"
        return 1
    fi
    
    log "Processing ${#APP_ARRAY[@]} applications..."
    
    # Check if install function exists
    if ! command -v install >/dev/null 2>&1; then
        log "⚠️ 'install' function not available, falling back to apt"
        for app in "${APP_ARRAY[@]}"; do
            if ! command -v "$app" >/dev/null 2>&1; then
                log "Installing $app with apt..."
                sudo apt-get install -y "$app" || log "❌ Failed to install $app"
            else
                log "✓ $app already installed"
            fi
        done
        return
    fi

    # Use the install function from pkg_aliases.bash
    local installed=0
    local skipped=0
    local failed=0
    
    for app in "${APP_ARRAY[@]}"; do
        if ! command -v "$app" >/dev/null 2>&1; then
            log "Installing $app..."
            if install "$app"; then
                log "✓ Installed $app"
                installed=$((installed + 1))
            else
                log "❌ Failed to install $app"
                failed=$((failed + 1))
            fi
            sleep 0.5
        else
            log "✓ $app already installed"
            skipped=$((skipped + 1))
        fi
    done
    
    log "Installation summary: $installed installed, $skipped skipped, $failed failed"
    [ $failed -gt 0 ] && return 1
    return 0
}

# =============================================================================
# BACKUP & SYMLINK MANAGEMENT
# =============================================================================

backup_dotfiles() {
    log "Backing up existing dotfiles..."
    mkdir -p "$OLD_FILES"
    
    local backed_up=0
    for f in "${OLD_FILE_ARRAY[@]}"; do
        if [ -f "$f" ] && [ ! -L "$f" ]; then
            if cp -p "$f" "$OLD_FILES/$(basename "$f").bak-$DATE"; then
                log "✓ Backed up: $f"
                backed_up=$((backed_up + 1))
            else
                log "❌ Failed to backup: $f"
            fi
        fi
    done
    
    if [ $backed_up -eq 0 ]; then
        log "No files to backup"
    else
        log "Backed up $backed_up files to $OLD_FILES/"
    fi
}

cleanup_symlinks() {
    log "Cleaning up old symlinks..."
    
    for file in "${DOT_ARRAY[@]}"; do
        if [ -L "$file" ]; then
            if [ ! -e "$file" ]; then
                # Broken symlink
                rm -f "$file"
                log "✓ Removed broken symlink: $file"
            fi
        elif [ -e "$file" ]; then
            # Regular file exists
            if mv "$file" "$OLD_FILES/$(basename "$file").moved-$DATE"; then
                log "✓ Moved existing file: $file -> $OLD_FILES/"
            else
                log "❌ Failed to move: $file"
            fi
        fi
    done
}

symlink_dotfiles() {
    log "Creating symlinks..."
    if [ ! -d "$DIR" ]; then
        log "❌ Error: $DIR not found. Clone repo first."
        exit 1
    fi
    
    local linked=0
    for src in "${DOT_ARRAY[@]}"; do
        local target="$DIR/$(basename "$src")"
        if [ ! -f "$target" ]; then
            log "⚠️ Warning: $target not found, skipping $(basename "$src")"
            continue
        fi

        if [ -e "$src" ] || [ -L "$src" ]; then
            rm -f "$src"
        fi

        if ln -sf "$target" "$src"; then
            log "✓ Linked: $target -> $src"
            linked=$((linked + 1))
        else
            log "❌ Failed to link: $src"
        fi
    done
    log "Created $linked symlinks"
    
    # Add/update headers in repo files
    log "Managing file headers..."
    [ -f "$DIR/.bashrc" ] && add_file_header "$DIR/.bashrc"
    [ -f "$DIR/.profile" ] && add_file_header "$DIR/.profile"
    [ -f "$DIR/.bash_profile" ] && add_file_header "$DIR/.bash_profile"
    
    # Call external symlink.sh with distro info
    if [ -x "$DIR/symlink.sh" ]; then
        log "Running distro-specific symlink script..."
        "$DIR/symlink.sh" "$DISTRO" "$DISTRO_BASE"
    else
        log "⚠️ symlink.sh not found or not executable"
    fi
    
    # Ensure bash_profile loads bashrc (check the actual file, not symlink)
    local bash_profile_target="$DIR/.bash_profile"
    if [ -f "$bash_profile_target" ]; then
        if ! grep -qE 'source.*bashrc|\..*bashrc' "$bash_profile_target" 2>/dev/null; then
            cat >> "$bash_profile_target" << 'EOF'
# Load .bashrc for interactive shells
if [ -n "$PS1" ] && [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF
            log "✓ Added .bashrc loader to .bash_profile (in repo)"
        else
            log "✓ .bash_profile already sources .bashrc"
        fi
    fi
}

# =============================================================================
# REPOSITORY MANAGEMENT
# =============================================================================

archive_backup() {
    local archived="$DIR/backup-${HOSTNAME}-$DATE.tar.gz"
    
    # Check if there are files to archive
    if [ -d "$OLD_FILES" ] && [ -n "$(ls -A "$OLD_FILES" 2>/dev/null)" ]; then
        if tar -czf "$archived" -C "$DIR" "oldfiles" 2>/dev/null; then
            log "✓ Archived backups: $archived"
        else
            log "⚠️  Failed to create archive"
            return 1
        fi
    else
        log "No files to archive"
    fi
}

update_submodules() {
    log "Updating git submodules..."
    
    if [ ! -d "$DIR/.git" ]; then
        log "⚠️  Not a git repository, skipping submodules"
        return
    fi
    
    cd "$DIR" || return
    
    if git submodule update --init --recursive 2>/dev/null; then
        git submodule foreach --recursive 'git pull origin master || git pull origin main' 2>/dev/null || true
        log "✓ Updated submodules"
    else
        log "⚠️  No submodules found or update failed"
    fi
}

clone_repos() {
    log "Cloning additional repositories..."
    cd "$HOME" || return
    
    # Helper to clone only when target does not exist
    clone_if_missing() {
    local repo_url="$1"
    local target_dir="$2"
    
    if [ -e "$target_dir" ]; then
        if [ -d "$target_dir/.git" ]; then
            log "✓ $target_dir exists and is a git repo; skipping clone"
        else
            log "⚠️ $target_dir exists (not a git repo); skipping clone to avoid overwrite"
        fi
        return 0  # ADD THIS - explicit success return
    fi
    
    log "Cloning $target_dir repository..."
    if GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules "$repo_url" "$target_dir" 2>/dev/null; then
        log "✓ Cloned $target_dir"
        return 0  # ADD THIS
    else
        log "⚠️ Failed to clone $target_dir (network/credentials?)"
        return 1  # ADD THIS
    fi
    }

    # Clone .tmux repo (into $HOME/.tmux) if missing
    clone_if_missing "https://bitbucket.org/b0red/tmux.git" "$HOME/.tmux"
    
    # Mark that RunMe.sh has handled tmux setup (with timestamp)
    if [ -d "$HOME/.tmux" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S')" > "$HOME/.tmux/.installed-by-runme"
        log "✓ Created marker: .tmux/.installed-by-runme"
    fi

    # Clone .vim repo (into $HOME/.vim) if missing
    clone_if_missing "https://bitbucket.org/b0red/.vim.git" "$HOME/.vim"

    clone_if_missing "https://github.com/tmux-plugins/tpm" "$HOME/.tmux/plugins/tpm"
}

symlink_external_repos() {
    log "Symlinking external repo configs..."
    
    local errors=0
    
    # Symlink .tmux.conf from .tmux repo
    if [ -d "$HOME/.tmux" ]; then
        if [ -f "$HOME/.tmux/.tmux.conf" ]; then
            if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
                rm -f "$HOME/.tmux.conf" || { log "❌ Failed to remove old .tmux.conf"; errors=$((errors + 1)); }
            fi
            if ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"; then
                log "✓ Linked: ~/.tmux/.tmux.conf -> ~/.tmux.conf"
            else
                log "❌ Failed to link .tmux.conf"
                errors=$((errors + 1))
            fi
        else
            log "⚠️ ~/.tmux/.tmux.conf not found, skipping"
        fi
    else
        log "⚠️ ~/.tmux directory not found, skipping .tmux.conf symlink"
    fi
    
    # Symlink .vimrc from .vim repo
    if [ -d "$HOME/.vim" ]; then
        if [ -f "$HOME/.vim/.vimrc" ]; then
            if [ -e "$HOME/.vimrc" ] || [ -L "$HOME/.vimrc" ]; then
                rm -f "$HOME/.vimrc" || { log "❌ Failed to remove old .vimrc"; errors=$((errors + 1)); }
            fi
            if ln -sf "$HOME/.vim/.vimrc" "$HOME/.vimrc"; then
                log "✓ Linked: ~/.vim/.vimrc -> ~/.vimrc"
            else
                log "❌ Failed to link .vimrc"
                errors=$((errors + 1))
            fi
        else
            log "⚠️ ~/.vim/.vimrc not found, skipping"
        fi
    else
        log "⚠️ ~/.vim directory not found, skipping .vimrc symlink"
    fi
    
    if [ $errors -gt 0 ]; then
        log "⚠️ $errors error(s) occurred during external repo symlinking"
        return 1
    fi
    return 0
}


# =============================================================================
# TMUX & SHELL CONFIGURATION
# =============================================================================

add_tmux_line() {
    log "Adding tmux integration..."
    
    # Add to the repo file, not the symlink
    local bashrc_file="$DIR/.bashrc"
    if [ ! -f "$bashrc_file" ]; then
        log "⚠️ $bashrc_file not found, skipping tmux integration"
        return 1  # ADD THIS
    fi
    
    if [ ! -w "$bashrc_file" ]; then  # ADD THIS CHECK
        log "❌ $bashrc_file not writable"
        return 1
    fi
    
    local tmux_line='if [ -f ~/.tmux-extras/tmux-git.sh ]; then source ~/.tmux-extras/tmux-git.sh; fi'
    
    if grep -qF "$tmux_line" "$bashrc_file" 2>/dev/null; then
        log "✓ Tmux integration already present in .bashrc"
    else
        if echo "$tmux_line" >> "$bashrc_file"; then  # ADD ERROR CHECK
            log "✓ Added tmux integration to .bashrc (in repo)"
        else
            log "❌ Failed to add tmux integration"
            return 1
        fi
    fi
    return 0  # ADD THIS
}


source_bashrc() {
    log "Configuration complete..."
    
    if [ -f "$HOME/.bashrc" ]; then
        log "✓ .bashrc is ready (restart shell to activate)"
    else
        log "⚠️  .bashrc not found"
    fi
}

# =============================================================================
# REVERT FUNCTIONALITY
# =============================================================================

revert_changes() {
    log "========================================="
    log "Reverting Dotfiles Installation"
    log "========================================="
    
    if [ ! -d "$OLD_FILES" ]; then
        log "❌ No backup directory found at: $OLD_FILES"
        log "Nothing to revert."
        return 1
    fi
    
    local reverted=0
    local failed=0
    
    # Restore backup files
    for f in "$OLD_FILES"/*.bak-* "$OLD_FILES"/*.moved-*; do
        [ -f "$f" ] || continue
        local basename_file=$(basename "$f" | sed 's/\.\(bak\|moved\)-.*$//')
        
        if cp -pf "$f" "$HOME/$basename_file"; then
            log "✓ Restored: $basename_file"
            reverted=$((reverted + 1))
        else
            log "❌ Failed to restore: $basename_file"
            failed=$((failed + 1))
        fi
    done
    
    # Remove symlinks
    local removed=0
    for src in "${DOT_ARRAY[@]}"; do
        if [ -L "$src" ]; then
            if rm -f "$src"; then
                log "✓ Removed symlink: $src"
                removed=$((removed + 1))
            else
                log "❌ Failed to remove: $src"
                failed=$((failed + 1))
            fi
        fi
    done
    
    log "========================================="
    log "Revert Summary:"
    log "  Files restored: $reverted"
    log "  Symlinks removed: $removed"
    [ $failed -gt 0 ] && log "  Failed operations: $failed"
    log "========================================="
    
    if [ $reverted -eq 0 ] && [ $removed -eq 0 ]; then
        log "⚠️  No changes were reverted. Check $OLD_FILES/ manually."
    fi
    
    log ""
    log "Manual cleanup steps (if needed):"
    log "  1. Review backups: ls -la $OLD_FILES/"
    log "  2. Remove dotfiles repo: rm -rf ~/dotfiles"
    log "  3. Restart your shell: exec bash"
    log ""
    log "See README.md for more information."
}

# =============================================================================
# HELP DOCUMENTATION
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: ./RunMe.sh [OPTIONS]

Options:
  -h, --help      Show this help message
  -r, --revert    Restore backups and remove symlinks
  --debug         Enable debug mode
  --trace         Enable trace mode (set -x)

Description:
  Installs dotfiles by:
    1. Backing up existing dotfiles
    2. Creating symlinks to dotfiles repo
    3. Installing essential applications
    4. Updating git submodules
    5. Cloning additional repos (.tmux, .vim)
    6. Adding tmux integration

Environment Variables:
  DEBUG=1         Enable debug output
  TRACE_DEBUG=1   Enable bash trace mode
  SLEEP=N         Seconds to sleep between operations (default: 2)

Log files are saved to: ~/dotfiles/logs/install-$(date +%Y-%m-%d).log/

Examples:
  ./RunMe.sh              # Normal installation
  ./RunMe.sh --revert     # Undo changes (restore backups)
  DEBUG=1 ./RunMe.sh      # Debug mode
  TRACE_DEBUG=1 ./RunMe.sh # Trace mode

For detailed documentation, see README.md
EOF
}

# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

# Setup cleanup trap
trap cleanup_on_exit EXIT

if [ "$TRACE_DEBUG" -eq 1 ]; then 
    set -x
    trap 'read -p "DEBUG: Press Enter..."' DEBUG
fi

if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run as root!"
    exit 1
fi

# =============================================================================
# COMMAND LINE ARGUMENT PARSING
# =============================================================================

case "${1:-}" in
    -h|--help|-\?)
        show_help
        exit 0
        ;;
    -r|--revert)
        logfile_init
        revert_changes
        exit 0
        ;;
    --debug)
        DEBUG=1
        main
        exit 0
        ;;
    --trace)
        TRACE_DEBUG=1
        main
        exit 0
        ;;
    "")
        main
        exit 0
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
# End of RunMe.sh