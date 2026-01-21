#!/usr/bin/env bash
# RunMe.sh - Dotfiles installer for first-run setup on new systems
# Backs up old files, symlinks dotfiles, installs apps, updates submodules.

set -euo pipefail

# Clear all aliases to avoid conflicts
unalias -a 2>/dev/null || true

# =============================================================================
# VERSION & CONFIGURATION
# =============================================================================
VERSION="15.1.1"
VERSION_DATE="2026-01-21"

DEBUG=${DEBUG:-0}
TRACE_DEBUG=${TRACE_DEBUG:-0}
SLEEP=${SLEEP:-2}
DIR="$HOME/dotfiles"
OLD_FILES="$DIR/oldfiles"
LOG_DIR="$DIR/logs"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
TITLE="Dotfiles Installer Script"
DOT_ARRAY=("$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.inputrc")
OLD_FILE_ARRAY=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.inputrc" "$HOME/.cshrc" "$HOME/.login")

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# RECURSION GUARD
# =============================================================================
if [ -n "${RUNME_INITIATED:-}" ]; then
    echo -e "${RED}RunMe.sh already running (PID $$)${NC}" >&2
    exit 1
fi
RUNME_INITIATED=1
export RUNME_INITIATED

# =============================================================================
# MAIN FUNCTION
# =============================================================================
function main() {
    logfile_init
    log "=========================================" "info"
    log "Starting Dotfiles Installation" "info"
    log "Version: v${VERSION} (${VERSION_DATE})" "info"
    log "=========================================" "info"
    
    if [ "${TRACE_DEBUG:-0}" -eq 1 ]; then
        set -x
        trap 'read -p "DEBUG: Press Enter..."' DEBUG
        log "✓ Trace enabled" "success"
    fi
    
    get_os_info
    load_package_functions || log "⚠️ Continuing without package functions" "warn"
    load_app_list || log "⚠️ Using fallback app list" "warn"
    
    # Prompt for sudo early
    log "" "info"
    log "🔐 Checking sudo access (you may be prompted for password)..." "info"
    if ! sudo -v; then
        log "❌ Sudo access required for package installation" "error"
        log "Run 'sudo -v' to verify sudo access, then try again." "error"
        exit 1
    fi
    log "✓ Sudo access verified" "success"
    log "" "info"
    
    backup_dotfiles
    cleanup_symlinks
    symlink_dotfiles "$DISTRO" "$DISTRO_BASE"
    install_apps
    archive_backup
    update_submodules
    clone_repos
    symlink_external_repos
    source_bashrc
    
    log "" "info"
    log "=========================================" "success"
    log "✓ Installation Complete!" "success"
    log "=========================================" "success"
    log "Log saved to: $LOG" "info"
    log "" "info"
    log "Next steps:" "info"
    log "  1. Restart your shell: exec bash" "info"
    log "  2. Or reload config: reload" "info"
    log "  3. Test package functions: version" "info"
    log "  4. Check for warnings above" "info"
    log "" "info"
    log "For troubleshooting, see: README.md" "info"
    log "To revert changes: ./RunMe.sh --revert" "info"
    log "=========================================" "success"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Logging function with color support
function log() {
    local msg="$1"
    local level="${2:-info}"
    local color=""
    
    # Write timestamped message to log file
    if [ -n "${LOG:-}" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG" 2>/dev/null || true
    fi
    
    # Determine color for screen output
    case "$level" in
        success|ok)
            color="$GREEN"
            ;;
        warn|warning|info)
            color="$YELLOW"
            ;;
        error|fail)
            color="$RED"
            ;;
        *)
            color="$NC"
            ;;
    esac
    
    # Print colored message to screen (no timestamp)
    echo -e "${color}${msg}${NC}"
}

function logfile_init() {
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo -e "${RED}❌ Failed to create log directory: $LOG_DIR${NC}" >&2
        exit 1
    fi
    
    LOG="$LOG_DIR/install-$DATE.log"
    
    # Write initial log entry
    if ! echo "[$(date +'%Y-%m-%d %H:%M:%S')] $TITLE started (PID $$)" > "$LOG" 2>/dev/null; then
        echo -e "${RED}❌ Failed to initialize log file: $LOG${NC}" >&2
        exit 1
    fi
    
    # Test color output
    if [ -t 1 ]; then
        log "🎨 Color output enabled" "success"
    fi
}

function check_or_add_line() {
    local line="$1" 
    local file="$2"
    
    # Validate inputs
    if [ -z "$line" ] || [ -z "$file" ]; then
        log "❌ check_or_add_line: Invalid arguments" "error"
        return 1
    fi
    
    # Don't modify symlinked files
    if [ -L "$file" ]; then
        log "⚠️ Skipping $file (symlink to repo)" "warn"
        return 0
    fi
    
    if [ ! -f "$file" ]; then
        if ! touch "$file" 2>/dev/null; then
            log "❌ Failed to create $file" "error"
            return 1
        fi
        log "Created empty $file" "info"
    fi
    
    if grep -qxF "$line" "$file" 2>/dev/null; then
        log "Line already exists in $file" "info"
    else
        if ! echo "$line" >> "$file" 2>/dev/null; then
            log "❌ Failed to add line to $file" "error"
            return 1
        fi
        log "Added line to $file" "success"
    fi
    
    return 0
}

function add_file_header() {
    local target_file="$1"
    local creation_date="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="${HOSTNAME:-$(hostname)}"
    
    # Validate input
    if [ -z "$target_file" ]; then
        log "❌ add_file_header: No target file specified" "error"
        return 1
    fi
    
    if [ ! -f "$target_file" ]; then
        log "⚠️ Target file does not exist: $target_file" "warn"
        return 1
    fi
    
    # Check if header already exists and remove it
    if grep -q "Created by RunMe.sh" "$target_file" 2>/dev/null; then
        log "Updating header in $(basename "$target_file")..." "info"
        
        local temp_file
        if ! temp_file=$(mktemp 2>/dev/null); then
            log "❌ Failed to create temp file" "error"
            return 1
        fi
        
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
        if ! tail -n +$((skip_lines + 1)) "$target_file" > "$temp_file" 2>/dev/null; then
            log "❌ Failed to process header" "error"
            rm -f "$temp_file"
            return 1
        fi
        
        if ! mv "$temp_file" "$target_file" 2>/dev/null; then
            log "❌ Failed to update file" "error"
            rm -f "$temp_file"
            return 1
        fi
    else
        log "Adding header to $(basename "$target_file")..." "info"
    fi
    
    # Create new header
    local temp_file
    if ! temp_file=$(mktemp 2>/dev/null); then
        log "❌ Failed to create temp file" "error"
        return 1
    fi
    
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
        if ! cat "$target_file" >> "$temp_file" 2>/dev/null; then
            log "❌ Failed to append content" "error"
            rm -f "$temp_file"
            return 1
        fi
    fi
    
    # Replace original
    if mv "$temp_file" "$target_file" 2>/dev/null; then
        log "✓ Header updated in $(basename "$target_file")" "success"
        return 0
    else
        log "❌ Failed to update header in $(basename "$target_file")" "error"
        rm -f "$temp_file"
        return 1
    fi
}

function cleanup_on_exit() {
    # Placeholder for cleanup operations
    :
}

# =============================================================================
# SYSTEM DETECTION
# =============================================================================

function get_os_info() {
    local os kernel mach distro distro_base
    
    # Basic system info
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    kernel=$(uname -r)
    mach=$(uname -m)
    
    DISTRO="unknown"
    DISTRO_BASE="unknown"
    
    case "$os" in
        linux*)
            # Linux distributions
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release 2>/dev/null
                distro="${ID:-unknown}"
                
                # Normalize distro name to base family
                case "$distro" in
                    ubuntu|debian|linuxmint|pop|peppermint|elementary|zorin)
                        DISTRO="$distro"
                        DISTRO_BASE="debian"
                        ;;
                    rhel|centos|fedora|rocky|almalinux|ol|oraclelinux)
                        DISTRO="$distro"
                        DISTRO_BASE="rhel"
                        ;;
                    arch|manjaro|endeavouros|garuda)
                        DISTRO="$distro"
                        DISTRO_BASE="arch"
                        ;;
                    opensuse*|suse|sles)
                        DISTRO="$distro"
                        DISTRO_BASE="suse"
                        ;;
                    gentoo)
                        DISTRO="gentoo"
                        DISTRO_BASE="gentoo"
                        ;;
                    alpine)
                        DISTRO="alpine"
                        DISTRO_BASE="alpine"
                        ;;
                    void)
                        DISTRO="void"
                        DISTRO_BASE="void"
                        ;;
                    *)
                        # Fallback: check ID_LIKE for derivative distros
                        if [ -n "${ID_LIKE:-}" ]; then
                            case "$ID_LIKE" in
                                *debian*|*ubuntu*)
                                    DISTRO="$distro"
                                    DISTRO_BASE="debian"
                                    ;;
                                *rhel*|*fedora*|*centos*)
                                    DISTRO="$distro"
                                    DISTRO_BASE="rhel"
                                    ;;
                                *arch*)
                                    DISTRO="$distro"
                                    DISTRO_BASE="arch"
                                    ;;
                                *suse*)
                                    DISTRO="$distro"
                                    DISTRO_BASE="suse"
                                    ;;
                                *)
                                    DISTRO="$distro"
                                    DISTRO_BASE="linux"
                                    log "Warning: Linux distribution '$distro' is not officially supported." "warn"
                                    ;;
                            esac
                        else
                            DISTRO="$distro"
                            DISTRO_BASE="linux"
                            log "Warning: Linux distribution '$distro' is not officially supported." "warn"
                        fi
                        ;;
                esac
            else
                # No /etc/os-release, try legacy methods
                if [ -f /etc/debian_version ]; then
                    DISTRO="debian"
                    DISTRO_BASE="debian"
                elif [ -f /etc/redhat-release ]; then
                    DISTRO="rhel"
                    DISTRO_BASE="rhel"
                elif [ -f /etc/arch-release ]; then
                    DISTRO="arch"
                    DISTRO_BASE="arch"
                else
                    DISTRO="linux"
                    DISTRO_BASE="linux"
                    log "Warning: Cannot determine Linux distribution" "warn"
                fi
            fi
            ;;
            
        darwin*)
            DISTRO="macos"
            DISTRO_BASE="macos"
            ;;
            
        freebsd*)
            DISTRO="freebsd"
            DISTRO_BASE="freebsd"
            ;;
            
        openbsd*)
            DISTRO="openbsd"
            DISTRO_BASE="openbsd"
            ;;
            
        netbsd*)
            DISTRO="netbsd"
            DISTRO_BASE="netbsd"
            ;;
            
        sunos*)
            DISTRO="solaris"
            DISTRO_BASE="solaris"
            ;;
            
        aix*)
            DISTRO="aix"
            DISTRO_BASE="aix"
            ;;
            
        cygwin*|mingw*|msys*)
            DISTRO="windows"
            DISTRO_BASE="windows"
            ;;
            
        *)
            DISTRO="unknown"
            DISTRO_BASE="unknown"
            log "Warning: Operating system '$os' is not recognized" "warn"
            ;;
    esac
    
    export OS="$os" KERNEL="$kernel" MACH="$mach" DISTRO DISTRO_BASE
    log "Detected: OS=$OS, Distro=$DISTRO, Base=$DISTRO_BASE, Kernel=$KERNEL, Arch=$MACH" "info"
}

# =============================================================================
# APPLICATION LIST MANAGEMENT
# =============================================================================

function load_app_list() {
    local app_file="$DIR/.install_apps.inc"
    
    if [ ! -r "$app_file" ]; then
        log "⚠️ Warning: $app_file not found" "warn"
        log "Using fallback app list" "warn"
        APP_ARRAY=(curl wget git vim tmux htop)
        return 1
    fi
    
    # Read file, filter comments and empty lines
    local apps=()
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove inline comments
        line="${line%%#*}"
        
        # Trim whitespace
        line=$(echo "$line" | xargs 2>/dev/null || echo "$line")
        
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Add to array
        apps+=("$line")
    done < "$app_file"
    
    if [ ${#apps[@]} -eq 0 ]; then
        log "⚠️ No apps found in $app_file" "warn"
        return 1
    fi
    
    APP_ARRAY=("${apps[@]}")
    log "✓ Loaded ${#APP_ARRAY[@]} applications from $app_file" "success"
    return 0
}

# =============================================================================
# PACKAGE MANAGEMENT - FIXED VERSION
# =============================================================================

function load_package_functions() {
    local pkg_file="$DIR/.bashrc.d/pkg_aliases.bash"
    
    if [ ! -r "$pkg_file" ]; then
        log "⚠️ Warning: $pkg_file not found or not readable" "warn"
        return 1
    fi
    
    log "Loading package management functions from $pkg_file..." "info"
    
    # Source the file - use 'source' not '.'
    # shellcheck disable=SC1090
    source "$pkg_file"
    
    log "✓ Package file sourced" "success"
    
    # Now call set_package_aliases (it won't auto-run since we're non-interactive)
    log "Calling set_package_aliases for distro: $DISTRO_BASE..." "info"
    
    if set_package_aliases 2>&1 | tee -a "$LOG"; then
        log "✅ Package functions configured for $DISTRO_BASE" "success"
    else
        log "❌ set_package_aliases failed" "error"
        return 1
    fi
    
    # Verify functions exist
    local missing_funcs=()
    for func in p_install p_remove p_update p_upgrade p_search; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            missing_funcs+=("$func")
        fi
    done
    
    if [ ${#missing_funcs[@]} -gt 0 ]; then
        log "⚠️ Some functions missing: ${missing_funcs[*]}" "warn"
        return 1
    fi
    
    log "✅ All package functions verified" "success"
    return 0
}

# =============================================================================
# APPLICATION INSTALLATION
# =============================================================================

function install_apps() {
    log "Installing applications..." "info"
    
    # Verify app list is loaded
    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log "❌ APP_ARRAY not loaded or empty" "error"
        return 1
    fi
    
    log "Processing ${#APP_ARRAY[@]} applications..." "info"
    
    # Check if p_install function exists
    if ! declare -f p_install >/dev/null 2>&1; then
        log "⚠️ 'p_install' function not available, using install_apps_direct" "warn"
        install_apps_direct
        return $?
    fi

    # Use the p_install function from pkg_aliases.bash
    local installed=0
    local skipped=0
    local failed=0
    
    for app in "${APP_ARRAY[@]}"; do
        # Map package names to actual command names for checking
        local check_cmd="$app"
        case "$app" in
            fd-find) check_cmd="fdfind" ;;
            bat) check_cmd="batcat" ;;
            ripgrep) check_cmd="rg" ;;
            silversearcher-ag) check_cmd="ag" ;;
        esac
        
        # Check if the actual command exists
        if command -v "$check_cmd" >/dev/null 2>&1; then
            log "✅ $app already installed (found: $check_cmd)" "success"
            skipped=$((skipped + 1))
            continue
        fi
        
        # Install using p_install function
        log "Installing $app..." "info"
        
        if p_install "$app" 2>&1 | tee -a "$LOG"; then
            log "✅ Installed $app" "success"
            installed=$((installed + 1))
        else
            log "❌ Failed to install $app" "error"
            failed=$((failed + 1))
        fi
        
        sleep 0.5
    done
    
    log "" "info"
    log "Installation summary: $installed installed, $skipped skipped, $failed failed" "info"
    [ $failed -gt 0 ] && return 1
    return 0
}

# Fallback: Call the package manager directly
function install_apps_direct() {
    log "Installing applications (direct package manager)..." "info"
    
    # Verify app list is loaded
    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log "❌ APP_ARRAY not loaded or empty" "error"
        return 1
    fi
    
    log "Processing ${#APP_ARRAY[@]} applications..." "info"
    
    local installed=0
    local skipped=0
    local failed=0
    
    # Detect package manager based on DISTRO_BASE
    local pkg_install=""
    case "${DISTRO_BASE:-unknown}" in
        debian|ubuntu)
            pkg_install="sudo apt-get install -y"
            ;;
        redhat|fedora|centos|rhel)
            if command -v dnf >/dev/null 2>&1; then
                pkg_install="sudo dnf install -y"
            else
                pkg_install="sudo yum install -y"
            fi
            ;;
        opensuse|suse)
            pkg_install="sudo zypper install -y"
            ;;
        arch|manjaro)
            pkg_install="sudo pacman -S --noconfirm"
            ;;
        *)
            log "❌ Unknown distro: $DISTRO_BASE" "error"
            return 1
            ;;
    esac
    
    for app in "${APP_ARRAY[@]}"; do
        # Map package names to actual command names for checking
        local check_cmd="$app"
        case "$app" in
            fd-find) check_cmd="fdfind" ;;
            bat) check_cmd="batcat" ;;
            ripgrep) check_cmd="rg" ;;
            silversearcher-ag) check_cmd="ag" ;;
            neovim) check_cmd="nvim" ;;
        esac
        
        # Check if already installed
        if command -v "$check_cmd" >/dev/null 2>&1; then
            log "✅ $app already installed (found: $check_cmd)" "success"
            skipped=$((skipped + 1))
            continue
        fi
        
        # Install the package
        log "Installing $app..." "info"
        if $pkg_install "$app" 2>&1 | tee -a "$LOG"; then
            log "✅ Installed $app" "success"
            installed=$((installed + 1))
        else
            log "❌ Failed to install $app" "error"
            failed=$((failed + 1))
        fi
        
        sleep 0.5
    done
    
    log "" "info"
    log "Installation summary: $installed installed, $skipped skipped, $failed failed" "info"
    [ $failed -gt 0 ] && return 1
    return 0
}

# =============================================================================
# BACKUP & SYMLINK MANAGEMENT
# =============================================================================

function backup_dotfiles() {
    log "Backing up existing dotfiles..." "info"
    
    if ! mkdir -p "$OLD_FILES" 2>/dev/null; then
        log "❌ Failed to create backup directory" "error"
        exit 1
    fi
    
    local backed_up=0
    local skipped_unchanged=0
    
    for f in "${OLD_FILE_ARRAY[@]}"; do
        if [ -f "$f" ] && [ ! -L "$f" ]; then
            local target="$DIR/$(basename "$f")"
            local backup_name="$(basename "$f").bak-$DATE"
            
            # Check if file has changed compared to repo version
            if [ -f "$target" ] && cmp -s "$f" "$target" 2>/dev/null; then
                log "⏭️  Skipping $f (unchanged from repo)" "info"
                skipped_unchanged=$((skipped_unchanged + 1))
                continue
            fi
            
            # Backup the file
            if cp -p "$f" "$OLD_FILES/$backup_name" 2>/dev/null; then
                log "✓ Backed up: $f" "success"
                backed_up=$((backed_up + 1))
            else
                log "❌ Failed to backup: $f" "error"
            fi
        fi
    done
    
    if [ $backed_up -eq 0 ]; then
        if [ $skipped_unchanged -gt 0 ]; then
            log "No new backups needed ($skipped_unchanged files unchanged)" "info"
        else
            log "No files to backup" "info"
        fi
    else
        log "Backed up $backed_up files to $OLD_FILES/" "success"
        [ $skipped_unchanged -gt 0 ] && log "Skipped $skipped_unchanged unchanged files" "info"
    fi
}

function cleanup_symlinks() {
    log "Cleaning up old symlinks..." "info"
    
    for file in "${DOT_ARRAY[@]}"; do
        if [ -L "$file" ]; then
            if [ ! -e "$file" ]; then
                # Broken symlink
                if rm -f "$file" 2>/dev/null; then
                    log "✓ Removed broken symlink: $file" "success"
                else
                    log "❌ Failed to remove broken symlink: $file" "error"
                fi
            fi
        elif [ -e "$file" ]; then
            # Regular file exists
            if mv "$file" "$OLD_FILES/$(basename "$file").moved-$DATE" 2>/dev/null; then
                log "✓ Moved existing file: $file -> $OLD_FILES/" "success"
            else
                log "❌ Failed to move: $file" "error"
            fi
        fi
    done
}

function symlink_dotfiles() {
    log "Creating symlinks..." "info"
    
    if [ ! -d "$DIR" ]; then
        log "❌ Error: $DIR not found. Clone repo first." "error"
        exit 1
    fi
    
    local linked=0
    for src in "${DOT_ARRAY[@]}"; do
        local target="$DIR/$(basename "$src")"
        if [ ! -f "$target" ]; then
            log "⚠️ Warning: $target not found, skipping $(basename "$src")" "warn"
            continue
        fi

        if [ -e "$src" ] || [ -L "$src" ]; then
            if ! rm -f "$src" 2>/dev/null; then
                log "❌ Failed to remove: $src" "error"
                continue
            fi
        fi

        if ln -sf "$target" "$src" 2>/dev/null; then
            log "✓ Linked: $target -> $src" "success"
            linked=$((linked + 1))
        else
            log "❌ Failed to link: $src" "error"
        fi
    done
    log "Created $linked symlinks" "success"
    
    # Add/update headers in repo files
    log "Managing file headers..." "info"
    [ -f "$DIR/.bashrc" ] && add_file_header "$DIR/.bashrc"
    [ -f "$DIR/.profile" ] && add_file_header "$DIR/.profile"
    [ -f "$DIR/.bash_profile" ] && add_file_header "$DIR/.bash_profile"
    
    # Call external symlink.sh with distro info
    if [ -x "$DIR/symlink.sh" ]; then
        log "Running distro-specific symlink script..." "info"
        if "$DIR/symlink.sh" "$DISTRO" "$DISTRO_BASE" 2>&1 | tee -a "$LOG"; then
            log "✓ Distro-specific symlinks created" "success"
        else
            log "⚠️ Distro-specific symlink script encountered issues" "warn"
        fi
    else
        log "⚠️ symlink.sh not found or not executable" "warn"
    fi
    
    # Ensure bash_profile loads bashrc
    local bash_profile_target="$DIR/.bash_profile"
    if [ -f "$bash_profile_target" ]; then
        if ! grep -qE 'source.*bashrc|\..*bashrc' "$bash_profile_target" 2>/dev/null; then
            if cat >> "$bash_profile_target" 2>/dev/null << 'EOF'
# Load .bashrc for interactive shells
if [ -n "$PS1" ] && [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF
            then
                log "✓ Added .bashrc loader to .bash_profile (in repo)" "success"
            else
                log "❌ Failed to add .bashrc loader" "error"
            fi
        else
            log "✓ .bash_profile already sources .bashrc" "success"
        fi
    fi
}

# =============================================================================
# REPOSITORY MANAGEMENT
# =============================================================================

function archive_backup() {
    local archived="$DIR/backup-${HOSTNAME}-$DATE.tar.gz"
    
    # Check if there are files to archive
    if [ -d "$OLD_FILES" ] && [ -n "$(ls -A "$OLD_FILES" 2>/dev/null)" ]; then
        if tar -czf "$archived" -C "$DIR" "oldfiles" 2>/dev/null; then
            log "✓ Archived backups: $archived" "success"
            
            # Clean up old archive files (keep only 3 most recent)
            cleanup_old_archives
        else
            log "⚠️ Failed to create archive" "warn"
            return 1
        fi
    else
        log "No files to archive" "info"
    fi
}

function cleanup_old_archives() {
    log "Cleaning up old backup archives (keeping 3 most recent)..." "info"
    
    # Find all backup-*.tar.gz files in the dotfiles directory
    shopt -s nullglob
    local archives=("$DIR"/backup-*-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].tar.gz)
    shopt -u nullglob
    
    local count=${#archives[@]}
    
    if [ $count -le 3 ]; then
        log "Keeping all $count archive(s) (3 or fewer exist)" "info"
        return 0
    fi
    
    # Sort archives by modification time (oldest first) and get files to delete
    local to_delete=$((count - 3))
    local deleted=0
    
    # Use ls -t to sort by time (newest first), then tail to get oldest
    local old_archives
    mapfile -t old_archives < <(ls -t "$DIR"/backup-*-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].tar.gz 2>/dev/null | tail -n $to_delete)
    
    for archive in "${old_archives[@]}"; do
        if [ -f "$archive" ]; then
            if rm -f "$archive" 2>/dev/null; then
                log "🗑️  Deleted old archive: $(basename "$archive")" "info"
                deleted=$((deleted + 1))
            else
                log "⚠️  Failed to delete: $(basename "$archive")" "warn"
            fi
        fi
    done
    
    if [ $deleted -gt 0 ]; then
        log "✓ Cleaned up $deleted old archive(s), kept 3 most recent" "success"
    else
        log "No old archives to clean up" "info"
    fi
}

function update_submodules() {
    log "Updating git submodules..." "info"
    
    if [ ! -d "$DIR/.git" ]; then
        log "⚠️ Not a git repository, skipping submodules" "warn"
        return 0
    fi
    
    if ! cd "$DIR" 2>/dev/null; then
        log "❌ Failed to cd to $DIR" "error"
        return 1
    fi
    
    if git submodule update --init --recursive 2>&1 | tee -a "$LOG"; then
        git submodule foreach --recursive 'git pull origin master || git pull origin main' 2>&1 | tee -a "$LOG" || true
        log "✓ Updated submodules" "success"
    else
        log "⚠️ No submodules found or update failed" "warn"
    fi
}

clone_repos() {
    log "Cloning additional repositories..." "info"
    
    if ! cd "$HOME" 2>/dev/null; then
        log "❌ Failed to cd to $HOME" "error"
        return 1
    fi
    
    # Helper to clone only when target does not exist
    function clone_if_missing() {
        local repo_url="$1"
        local target_dir="$2"
        
        # Validate inputs
        if [ -z "$repo_url" ] || [ -z "$target_dir" ]; then
            log "❌ clone_if_missing: Invalid arguments" "error"
            return 1
        fi
        
        if [ -e "$target_dir" ]; then
            if [ -d "$target_dir/.git" ]; then
                log "✓ $target_dir exists and is a git repo; skipping clone" "success"
            else
                log "⚠️ $target_dir exists (not a git repo); skipping clone to avoid overwrite" "warn"
            fi
            return 0
        fi
        
        log "Cloning $(basename "$target_dir") repository..." "info"
        if GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules "$repo_url" "$target_dir" 2>&1 | tee -a "$LOG"; then
            log "✓ Cloned $target_dir" "success"
            return 0
        else
            log "⚠️ Failed to clone $target_dir (network/credentials?)" "warn"
            return 1
        fi
    }

    # Clone .tmux repo
    clone_if_missing "https://bitbucket.org/b0red/tmux.git" "$HOME/.tmux"
    
    # Mark that RunMe.sh has handled tmux setup
    if [ -d "$HOME/.tmux" ]; then
        if echo "$(date +'%Y-%m-%d %H:%M:%S')" > "$HOME/.tmux/.installed-by-runme" 2>/dev/null; then
            log "✓ Created marker: .tmux/.installed-by-runme" "success"
        else
            log "⚠️ Failed to create marker file" "warn"
        fi
    fi

    # Clone .vim repo
    clone_if_missing "https://bitbucket.org/b0red/.vim.git" "$HOME/.vim"

    # Clone tpm
    clone_if_missing "https://github.com/tmux-plugins/tpm" "$HOME/.tmux/plugins/tpm"
}

function symlink_external_repos() {
    log "Symlinking external repo configs..." "info"
    
    local errors=0
    
    # Symlink .tmux.conf from .tmux repo
    if [ -d "$HOME/.tmux" ]; then
        if [ -f "$HOME/.tmux/.tmux.conf" ]; then
            if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
                if ! rm -f "$HOME/.tmux.conf" 2>/dev/null; then
                    log "❌ Failed to remove old .tmux.conf" "error"
                    errors=$((errors + 1))
                fi
            fi
            if [ $errors -eq 0 ]; then
                if ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null; then
                    log "✓ Linked: ~/.tmux/.tmux.conf -> ~/.tmux.conf" "success"
                else
                    log "❌ Failed to link .tmux.conf" "error"
                    errors=$((errors + 1))
                fi
            fi
        else
            log "⚠️ ~/.tmux/.tmux.conf not found, skipping" "warn"
        fi
    else
        log "⚠️ ~/.tmux directory not found, skipping .tmux.conf symlink" "warn"
    fi
    
    # Symlink .vimrc from .vim repo
    if [ -d "$HOME/.vim" ]; then
        if [ -f "$HOME/.vim/.vimrc" ]; then
            if [ -e "$HOME/.vimrc" ] || [ -L "$HOME/.vimrc" ]; then
                if ! rm -f "$HOME/.vimrc" 2>/dev/null; then
                    log "❌ Failed to remove old .vimrc" "error"
                    errors=$((errors + 1))
                fi
            fi
            if ln -sf "$HOME/.vim/.vimrc" "$HOME/.vimrc" 2>/dev/null; then
                log "✓ Linked: ~/.vim/.vimrc -> ~/.vimrc" "success"
            else
                log "❌ Failed to link .vimrc" "error"
                errors=$((errors + 1))
            fi
        else
            log "⚠️ ~/.vim/.vimrc not found, skipping" "warn"
        fi
    else
        log "⚠️ ~/.vim directory not found, skipping .vimrc symlink" "warn"
    fi
    
    if [ $errors -gt 0 ]; then
        log "⚠️ $errors error(s) occurred during external repo symlinking" "warn"
        return 1
    fi
    return 0
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

function source_bashrc() {
    log "Configuration complete..." "info"
    
    if [ -f "$HOME/.bashrc" ]; then
        log "✓ .bashrc is ready" "success"
        log "" "info"
        log "To activate changes:" "info"
        log "  Option 1: Restart shell: exec bash" "info"
        log "  Option 2: Reload config: reload" "info"
    else
        log "⚠️ .bashrc not found" "warn"
    fi
}

# =============================================================================
# REVERT FUNCTIONALITY
# =============================================================================

function revert_changes() {
    log "=========================================" "info"
    log "Reverting Dotfiles Installation" "info"
    log "=========================================" "info"
    
    if [ ! -d "$OLD_FILES" ]; then
        log "❌ No backup directory found at: $OLD_FILES" "error"
        log "Nothing to revert." "info"
        return 1
    fi
    
    local reverted=0
    local failed=0
    
    # Restore backup files
    shopt -s nullglob  # Handle case when no files match
    for f in "$OLD_FILES"/*.bak-* "$OLD_FILES"/*.moved-*; do
        [ -f "$f" ] || continue
        local basename_file=$(basename "$f" | sed 's/\.\(bak\|moved\)-.*$//')
        
        if cp -pf "$f" "$HOME/$basename_file" 2>/dev/null; then
            log "✓ Restored: $basename_file" "success"
            reverted=$((reverted + 1))
        else
            log "❌ Failed to restore: $basename_file" "error"
            failed=$((failed + 1))
        fi
    done
    shopt -u nullglob  # Restore default behavior
    
    # Remove symlinks
    local removed=0
    for src in "${DOT_ARRAY[@]}"; do
        if [ -L "$src" ]; then
            if rm -f "$src" 2>/dev/null; then
                log "✓ Removed symlink: $src" "success"
                removed=$((removed + 1))
            else
                log "❌ Failed to remove: $src" "error"
                failed=$((failed + 1))
            fi
        fi
    done
    
    log "=========================================" "info"
    log "Revert Summary:" "info"
    log "  Files restored: $reverted" "info"
    log "  Symlinks removed: $removed" "info"
    [ $failed -gt 0 ] && log "  Failed operations: $failed" "error"
    log "=========================================" "info"
    
    if [ $reverted -eq 0 ] && [ $removed -eq 0 ]; then
        log "⚠️ No changes were reverted. Check $OLD_FILES/ manually." "warn"
    fi
    
    log "" "info"
    log "Manual cleanup steps (if needed):" "info"
    log "  1. Review backups: ls -la $OLD_FILES/" "info"
    log "  2. Remove dotfiles repo: rm -rf ~/dotfiles" "info"
    log "  3. Restart your shell: exec bash" "info"
    log "" "info"
    log "See README.md for more information." "info"
}

# =============================================================================
# HELP DOCUMENTATION
# =============================================================================

function show_version() {
    echo -e "${GREEN}${BOLD}RunMe.sh${NC} version ${BLUE}v${VERSION}${NC} (${VERSION_DATE})"
    echo ""
    echo "Dotfiles installer and configuration manager"
    echo "https://github.com/yourusername/dotfiles"
}

function show_help() {
    echo -e "${BOLD}Usage:${NC} ./RunMe.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -h, --help      Show this help message"
    echo "  -v, --version   Show version information"
    echo "  -r, --revert    Restore backups and remove symlinks"
    echo "  --debug         Enable debug mode"
    echo "  --trace         Enable trace mode (set -x)"
    echo ""
    echo -e "${BOLD}Description:${NC}"
    echo "  Installs dotfiles by:"
    echo "    1. Backing up existing dotfiles"
    echo "    2. Creating symlinks to dotfiles repo"
    echo "    3. Installing essential applications"
    echo "    4. Updating git submodules"
    echo "    5. Cloning additional repos (.tmux, .vim)"
    echo ""
    echo -e "${BOLD}Environment Variables:${NC}"
    echo "  DEBUG=1         Enable debug output"
    echo "  TRACE_DEBUG=1   Enable bash trace mode"
    echo "  SLEEP=N         Seconds to sleep between operations (default: 2)"
    echo ""
    echo -e "${BOLD}Log files:${NC}"
    echo "  ~/dotfiles/logs/install-YYYY-MM-DD_HH-MM-SS.log"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./RunMe.sh              # Normal installation"
    echo "  ./RunMe.sh --version    # Show version"
    echo "  ./RunMe.sh --revert     # Undo changes (restore backups)"
    echo "  DEBUG=1 ./RunMe.sh      # Debug mode"
    echo "  TRACE_DEBUG=1 ./RunMe.sh # Trace mode"
    echo ""
    echo -e "${BOLD}For detailed documentation, see:${NC} README.md"
}


# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

# Setup cleanup trap
trap cleanup_on_exit EXIT

if [ "${TRACE_DEBUG:-0}" -eq 1 ]; then 
    set -x
    trap 'read -p "DEBUG: Press Enter..."' DEBUG
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run as root!${NC}"
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
    -v|--version)
        show_version
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
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

# End of RunMe.sh