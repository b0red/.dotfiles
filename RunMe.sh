#!/usr/bin/env bash
# RunMe.sh - Dotfiles installer for first-run setup on new systems
# Backs up old files, symlinks dotfiles, installs apps, updates submodules.

set -euo pipefail

# Clear all aliases to avoid conflicts
unalias -a 2>/dev/null || true

# =============================================================================
# VERSION & CONFIGURATION
# =============================================================================
VERSION="16.0.0"
VERSION_DATE="2026-02-18"

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
main() {
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
    symlink_dotfiles
    install_apps
    archive_backup
    update_submodules
    clone_repos
    symlink_external_repos
    symlink_config_folders
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

log() {
    local msg="$1"
    local level="${2:-info}"
    local color=""
    
    if [ -n "${LOG:-}" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG" 2>/dev/null || true
    fi
    
    case "$level" in
        success|ok) color="$GREEN" ;;
        warn|warning|info) color="$YELLOW" ;;
        error|fail) color="$RED" ;;
        *) color="$NC" ;;
    esac
    
    echo -e "${color}${msg}${NC}"
}

logfile_init() {
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo -e "${RED}❌ Failed to create log directory: $LOG_DIR${NC}" >&2
        exit 1
    fi
    
    LOG="$LOG_DIR/install-$DATE.log"
    
    if ! echo "[$(date +'%Y-%m-%d %H:%M:%S')] $TITLE started (PID $$)" > "$LOG" 2>/dev/null; then
        echo -e "${RED}❌ Failed to initialize log file: $LOG${NC}" >&2
        exit 1
    fi
    
    if [ -t 1 ]; then
        log "🎨 Color output enabled" "success"
    fi
}

# Corrected version with shellcheck best practices
# Note: This function is currently unused but kept for future use
# shellcheck disable=SC2329
check_or_add_line() {
    local line="$1" 
    local file="$2"
    
    # Check for empty arguments
    if [[ -z "$line" ]] || [[ -z "$file" ]]; then
        log "❌ check_or_add_line: Invalid arguments" "error"
        return 1
    fi
    
    # Check if file is a symlink
    if [[ -L "$file" ]]; then
        log "⚠️ Skipping $file (symlink to repo)" "warn"
        return 0
    fi
    
    # Create file if it doesn't exist
    if [[ ! -f "$file" ]]; then
        if ! touch "$file" 2>/dev/null; then
            log "❌ Failed to create $file" "error"
            return 1
        fi
        log "Created empty $file" "info"
    fi
    
    # Check if line already exists, if not add it
    if grep -qxF "$line" "$file" 2>/dev/null; then
        log "Line already exists in $file" "info"
    else
        if ! printf '%s\n' "$line" >> "$file" 2>/dev/null; then
            log "❌ Failed to add line to $file" "error"
            return 1
        fi
        log "Added line to $file" "success"
    fi
    
    return 0
}

add_file_header() {
    local target_file="$1"
    local creation_date
    creation_date="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="${HOSTNAME:-$(hostname)}"
    
    if [ -z "$target_file" ]; then
        log "❌ add_file_header: No target file specified" "error"
        return 1
    fi
    
    if [ ! -f "$target_file" ]; then
        log "⚠️ Target file does not exist: $target_file" "warn"
        return 1
    fi
    
    local temp_file
    if ! temp_file=$(mktemp 2>/dev/null); then
        log "❌ Failed to create temp file" "error"
        return 1
    fi
    
    # Check if file starts with shebang
    local has_shebang=0
    local shebang_line=""
    if head -n 1 "$target_file" | grep -q '^#!'; then
        has_shebang=1
        shebang_line=$(head -n 1 "$target_file")
    fi
    
    # Remove old header if exists
    local content_start=1
    if grep -q "Created by RunMe.sh" "$target_file" 2>/dev/null; then
        log "Updating header in $(basename "$target_file")..." "info"
        
        # Skip shebang if present
        if [ "$has_shebang" -eq 1 ]; then
            content_start=2
        fi
        
        # Find where old header ends
        local line_num=$content_start
        while IFS= read -r line; do
            if [[ "$line" =~ ^###.*-\+- ]] || [[ "$line" =~ ^###.*Created\ by\ RunMe\.sh ]] || \
               [[ "$line" =~ ^###.*Host: ]] || [[ "$line" =~ ^###.*User: ]] || \
               [[ "$line" =~ ^###.*Distro: ]] || [[ "$line" =~ ^$ && $line_num -lt 10 ]]; then
                line_num=$((line_num + 1))
            else
                break
            fi
        done < <(tail -n +$content_start "$target_file")
        
        content_start=$line_num
    else
        log "Adding header to $(basename "$target_file")..." "info"
        # If no old header, skip just the shebang
        if [ "$has_shebang" -eq 1 ]; then
            content_start=2
        fi
    fi
    
    # Build new file
    {
        # 1. Write shebang if present
        if [ "$has_shebang" -eq 1 ]; then
            echo "$shebang_line"
        fi
        
        # 2. Write new header
        cat << EOF
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh $creation_date
###                                             Host: $hostname
###                                             User: ${USER:-$(whoami)}
###                                             Distro: $DISTRO
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

EOF
        
        # 3. Write remaining content (skip header and shebang)
        tail -n +$content_start "$target_file"
    } > "$temp_file"
    
    # Replace original file
    if mv "$temp_file" "$target_file" 2>/dev/null; then
        log "✓ Header updated in $(basename "$target_file")" "success"
        return 0
    else
        log "❌ Failed to update header in $(basename "$target_file")" "error"
        rm -f "$temp_file"
        return 1
    fi
}

cleanup_on_exit() {
    # Placeholder for cleanup logic
    # Currently no cleanup needed as temp files are handled inline
    # and script uses 'set -e' for automatic error handling
    :
}

# =============================================================================
# SYSTEM DETECTION
# =============================================================================

get_os_info() {
    local os kernel mach distro
    
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    kernel=$(uname -r)
    mach=$(uname -m)
    
    DISTRO="unknown"
    DISTRO_BASE="unknown"
    
    case "$os" in
        linux*)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release 2>/dev/null
                distro="${ID:-unknown}"
                
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
        darwin*) DISTRO="macos"; DISTRO_BASE="macos" ;;
        freebsd*) DISTRO="freebsd"; DISTRO_BASE="freebsd" ;;
        openbsd*) DISTRO="openbsd"; DISTRO_BASE="openbsd" ;;
        netbsd*) DISTRO="netbsd"; DISTRO_BASE="netbsd" ;;
        sunos*) DISTRO="solaris"; DISTRO_BASE="solaris" ;;
        aix*) DISTRO="aix"; DISTRO_BASE="aix" ;;
        cygwin*|mingw*|msys*) DISTRO="windows"; DISTRO_BASE="windows" ;;
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

load_app_list() {
    local app_file="$DIR/.install_apps.inc"
    
    if [ ! -r "$app_file" ]; then
        log "⚠️ Warning: $app_file not found" "warn"
        log "Using fallback app list" "warn"
        APP_ARRAY=(curl wget git vim tmux htop)
        return 1
    fi
    
    local apps=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line=$(echo "$line" | xargs 2>/dev/null || echo "$line")
        [ -z "$line" ] && continue
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
# PACKAGE MANAGEMENT
# =============================================================================

load_package_functions() {
    local pkg_file="$DIR/.bashrc.d/pkg_aliases.bash"
    
    if [ ! -r "$pkg_file" ]; then
        log "⚠️ Warning: $pkg_file not found or not readable" "warn"
        return 1
    fi
    
    log "Loading package management functions from $pkg_file..." "info"
    
    export DISTROBASE="$DISTRO_BASE"
    
    # shellcheck disable=SC1090
    source "$pkg_file"
    
    log "✓ Package file sourced" "success"
    
    log "Calling set_package_aliases for distro: $DISTRO_BASE..." "info"
    
    if set_package_aliases 2>&1 | tee -a "$LOG"; then
        log "✅ Package functions configured for $DISTRO_BASE" "success"
    else
        log "❌ set_package_aliases failed" "error"
        return 1
    fi
    
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

install_apps() {
    log "Installing applications..." "info"
    
    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log "❌ APP_ARRAY not loaded or empty" "error"
        return 1
    fi
    
    log "Processing ${#APP_ARRAY[@]} applications..." "info"
    
    if ! declare -f p_install >/dev/null 2>&1; then
        log "⚠️ 'p_install' function not available, using install_apps_direct" "warn"
        install_apps_direct
        return $?
    fi

    local installed=0 skipped=0 failed=0
    
    for app in "${APP_ARRAY[@]}"; do
        local check_cmd="$app"
        case "$app" in
            fd-find) check_cmd="fdfind" ;;
            bat) check_cmd="batcat" ;;
            ripgrep) check_cmd="rg" ;;
            silversearcher-ag) check_cmd="ag" ;;
        esac
        
        if command -v "$check_cmd" >/dev/null 2>&1; then
            log "✅ $app already installed (found: $check_cmd)" "success"
            skipped=$((skipped + 1))
            continue
        fi
        
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
    if [ $failed -gt 0 ]; then
        return 1
    fi
    return 0
}

install_apps_direct() {
    log "Installing applications (direct package manager)..." "info"
    
    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log "❌ APP_ARRAY not loaded or empty" "error"
        return 1
    fi
    
    log "Processing ${#APP_ARRAY[@]} applications..." "info"
    
    local installed=0 skipped=0 failed=0
    local pkg_install=""
    
    case "${DISTRO_BASE:-unknown}" in
        debian|ubuntu) pkg_install="sudo apt-get install -y" ;;
        redhat|fedora|centos|rhel)
            if command -v dnf >/dev/null 2>&1; then
                pkg_install="sudo dnf install -y"
            else
                pkg_install="sudo yum install -y"
            fi
            ;;
        opensuse|suse) pkg_install="sudo zypper install -y" ;;
        arch|manjaro) pkg_install="sudo pacman -S --noconfirm" ;;
        *)
            log "❌ Unknown distro: $DISTRO_BASE" "error"
            return 1
            ;;
    esac
    
    for app in "${APP_ARRAY[@]}"; do
        local check_cmd="$app"
        case "$app" in
            fd-find) check_cmd="fdfind" ;;
            bat) check_cmd="batcat" ;;
            ripgrep) check_cmd="rg" ;;
            silversearcher-ag) check_cmd="ag" ;;
            neovim) check_cmd="nvim" ;;
        esac
        
        if command -v "$check_cmd" >/dev/null 2>&1; then
            log "✅ $app already installed (found: $check_cmd)" "success"
            skipped=$((skipped + 1))
            continue
        fi
        
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
    if [ $failed -gt 0 ]; then
        return 1
    fi
    return 0
}

# =============================================================================
# BACKUP & SYMLINK MANAGEMENT
# =============================================================================

backup_dotfiles() {
    log "Backing up existing dotfiles..." "info"
    
    if ! mkdir -p "$OLD_FILES" 2>/dev/null; then
        log "❌ Failed to create backup directory" "error"
        exit 1
    fi
    
    local backed_up=0 skipped_unchanged=0
    
    for f in "${OLD_FILE_ARRAY[@]}"; do
        if [ -f "$f" ] && [ ! -L "$f" ]; then
            local target
            target="$DIR/$(basename "$f")"
            local backup_name
            backup_name="$(basename "$f").bak-$DATE"
            
            if [ -f "$target" ] && cmp -s "$f" "$target" 2>/dev/null; then
                log "⏭️  Skipping $f (unchanged from repo)" "info"
                skipped_unchanged=$((skipped_unchanged + 1))
                continue
            fi
            
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
        if [ $skipped_unchanged -gt 0 ]; then
            log "Skipped $skipped_unchanged unchanged files" "info"
        fi
    fi
}

cleanup_symlinks() {
    log "Cleaning up old symlinks..." "info"
    
    for file in "${DOT_ARRAY[@]}"; do
        if [ -L "$file" ]; then
            if [ ! -e "$file" ]; then
                if rm -f "$file" 2>/dev/null; then
                    log "✓ Removed broken symlink: $file" "success"
                else
                    log "❌ Failed to remove broken symlink: $file" "error"
                fi
            fi
        elif [ -e "$file" ]; then
            if mv "$file" "$OLD_FILES/$(basename "$file").moved-$DATE" 2>/dev/null; then
                log "✓ Moved existing file: $file -> $OLD_FILES/" "success"
            else
                log "❌ Failed to move: $file" "error"
            fi
        fi
    done
}

symlink_dotfiles() {
    log "Creating symlinks..." "info"
    
    if [ ! -d "$DIR" ]; then
        log "❌ Error: $DIR not found. Clone repo first." "error"
        exit 1
    fi
    
    local linked=0
    for src in "${DOT_ARRAY[@]}"; do
        local target
        target="$DIR/$(basename "$src")"
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
    
    log "Managing file headers..." "info"
    if [ -f "$DIR/.bashrc" ]; then add_file_header "$DIR/.bashrc"; fi
    if [ -f "$DIR/.profile" ]; then add_file_header "$DIR/.profile"; fi
    if [ -f "$DIR/.bash_profile" ]; then add_file_header "$DIR/.bash_profile"; fi
    
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

archive_backup() {
    local archived="$DIR/backup-${HOSTNAME}-$DATE.tar.gz"
    
    if [ -d "$OLD_FILES" ] && [ -n "$(ls -A "$OLD_FILES" 2>/dev/null)" ]; then
        if tar -czf "$archived" -C "$DIR" "oldfiles" 2>/dev/null; then
            log "✓ Archived backups: $archived" "success"
            cleanup_old_archives
        else
            log "⚠️ Failed to create archive" "warn"
            return 1
        fi
    else
        log "No files to archive" "info"
    fi
}

cleanup_old_archives() {
    log "Cleaning up old backup archives (keeping 3 most recent)..." "info"
    
    shopt -s nullglob
    local archives=("$DIR"/backup-*-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].tar.gz)
    shopt -u nullglob
    
    local count=${#archives[@]}
    
    if [ $count -le 3 ]; then
        log "Keeping all $count archive(s) (3 or fewer exist)" "info"
        return 0
    fi
    
    local to_delete=$((count - 3))
    local deleted=0
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

update_submodules() {
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

# =============================================================================
# REPOSITORY CLONING - IMPROVED VERSION
# =============================================================================

clone_repos() {
    log "Cloning additional repositories..." "info"
    
    local original_dir
    original_dir=$(pwd)
    
    if ! cd "$HOME" 2>/dev/null; then
        log "❌ Failed to cd to $HOME" "error"
        return 1
    fi
    
    clone_if_missing() {
        local repo_url="$1"
        local target_dir="$2"
        local repo_name
        repo_name=$(basename "$target_dir")
        
        if [ -z "$repo_url" ]; then
            log "❌ clone_if_missing: No repository URL provided" "error"
            return 1
        fi
        
        if [ -z "$target_dir" ]; then
            log "❌ clone_if_missing: No target directory provided" "error"
            return 1
        fi
        
        if [ -e "$target_dir" ]; then
            if [ -d "$target_dir/.git" ]; then
                log "✓ $repo_name exists and is a git repo" "success"
                
                local current_remote
                current_remote=$(git -C "$target_dir" config --get remote.origin.url 2>/dev/null || echo "")
                
                if [ -n "$current_remote" ]; then
                    local normalized_current normalized_expected
                    normalized_current=$(echo "$current_remote" | sed 's/\.git$//' | tr '[:upper:]' '[:lower:]')
                    normalized_expected=$(echo "$repo_url" | sed 's/\.git$//' | tr '[:upper:]' '[:lower:]')
                    
                    if [[ "$normalized_current" == "$normalized_expected" ]] || \
                       [[ "$normalized_current" == *"${normalized_expected##*/}" ]] || \
                       [[ "$normalized_expected" == *"${normalized_current##*/}" ]]; then
                        log "  Remote URL matches expected repository" "info"
                    else
                        log "⚠️  Warning: Remote URL differs from expected" "warn"
                        log "  Current:  $current_remote" "warn"
                        log "  Expected: $repo_url" "warn"
                    fi
                else
                    log "⚠️  Warning: Could not verify remote URL" "warn"
                fi
                
                if git -C "$target_dir" diff-index --quiet HEAD -- 2>/dev/null; then
                    log "  Repository is clean (no uncommitted changes)" "info"
                else
                    log "⚠️  Repository has uncommitted changes" "warn"
                fi
                
                return 0
            else
                log "⚠️  $target_dir exists but is not a git repository" "warn"
                log "  Skipping clone to avoid overwriting existing directory" "warn"
                log "  To fix: mv $target_dir ${target_dir}.backup && re-run script" "warn"
                return 1
            fi
        fi
        
        log "Cloning $repo_name repository..." "info"
        log "  Source: $repo_url" "info"
        log "  Target: $target_dir" "info"
        
        if GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules "$repo_url" "$target_dir" 2>&1 | tee -a "$LOG"; then
            log "✓ Successfully cloned $repo_name" "success"
            
            if [ -d "$target_dir/.git" ]; then
                log "  ✓ Git repository structure verified" "success"
                
                if [ -f "$target_dir/.gitmodules" ]; then
                    log "  Repository contains submodules" "info"
                    
                    if git -C "$target_dir" submodule status 2>/dev/null | grep -q '^-'; then
                        log "⚠️  Some submodules may not be initialized" "warn"
                        log "  Initializing submodules..." "info"
                        if git -C "$target_dir" submodule update --init --recursive 2>&1 | tee -a "$LOG"; then
                            log "  ✓ Submodules initialized" "success"
                        else
                            log "  ⚠️  Failed to initialize some submodules" "warn"
                        fi
                    else
                        log "  ✓ Submodules initialized" "success"
                    fi
                fi
                
                return 0
            else
                log "❌ Clone appeared to succeed but git directory not found" "error"
                return 1
            fi
        else
            local exit_code=$?
            log "❌ Failed to clone $repo_name (exit code: $exit_code)" "error"
            
            case $exit_code in
                128)
                    log "  Common causes:" "error"
                    log "    • Repository URL is incorrect" "error"
                    log "    • No network connectivity" "error"
                    log "    • SSH key not configured (for git@ URLs)" "error"
                    log "    • Repository doesn't exist or is private" "error"
                    ;;
                *)
                    log "  Check network connectivity and repository access" "error"
                    ;;
            esac
            
            if [ -d "$target_dir" ] && [ ! -d "$target_dir/.git" ]; then
                log "  Cleaning up incomplete clone directory..." "warn"
                if rm -rf "$target_dir" 2>/dev/null; then
                    log "  ✓ Cleaned up incomplete directory" "success"
                else
                    log "  ⚠️  Failed to clean up $target_dir" "warn"
                fi
            fi
            
            return 1
        fi
    }
    
    log "" "info"
    log "Processing tmux repository..." "info"
    
    if clone_if_missing "git@bitbucket.org:b0red/tmux.git" "$HOME/.tmux"; then
        if [ -d "$HOME/.tmux" ]; then
            local marker_file="$HOME/.tmux/.installed-by-runme"
            local install_timestamp
            install_timestamp=$(date +'%Y-%m-%d %H:%M:%S')
            
            if echo "$install_timestamp" > "$marker_file" 2>/dev/null; then
                log "✓ Created installation marker: .tmux/.installed-by-runme" "success"
                log "  Timestamp: $install_timestamp" "info"
            else
                log "⚠️  Failed to create installation marker" "warn"
                log "  This is not critical but TmuxInstaller.sh won't detect RunMe.sh installation" "warn"
            fi
            
            if [ -f "$HOME/.tmux/.tmux.conf" ]; then
                log "✓ Found .tmux.conf in repository" "success"
            else
                log "⚠️  .tmux.conf not found in repository" "warn"
                log "  Symlink creation may fail later" "warn"
            fi
        else
            log "⚠️  .tmux directory doesn't exist after clone" "warn"
        fi
    else
        log "⚠️  tmux repository clone failed or was skipped" "warn"
        log "  You can clone it manually with:" "warn"
        log "    git clone git@bitbucket.org:b0red/tmux.git ~/.tmux" "warn"
    fi
    
    log "" "info"
    log "Processing vim repository..." "info"
    
    if clone_if_missing "git@bitbucket.org:b0red/.vim.git" "$HOME/.vim"; then
        if [ -f "$HOME/.vim/.vimrc" ]; then
            log "✓ Found .vimrc in repository" "success"
        else
            log "⚠️  .vimrc not found in repository" "warn"
            log "  Symlink creation may fail later" "warn"
        fi
    else
        log "⚠️  vim repository clone failed or was skipped" "warn"
        log "  You can clone it manually with:" "warn"
        log "    git clone git@bitbucket.org:b0red/.vim.git ~/.vim" "warn"
    fi
    
    log "" "info"
    log "Processing TPM (Tmux Plugin Manager)..." "info"
    
    if [ ! -d "$HOME/.tmux/plugins" ]; then
        if mkdir -p "$HOME/.tmux/plugins" 2>/dev/null; then
            log "✓ Created plugins directory: ~/.tmux/plugins" "success"
        else
            log "⚠️  Failed to create plugins directory" "warn"
            log "  TPM installation will be skipped" "warn"
        fi
    fi
    
    if clone_if_missing "https://github.com/tmux-plugins/tpm" "$HOME/.tmux/plugins/tpm"; then
        log "✓ TPM installation complete" "success"
        log "  Press prefix + I (capital i) in tmux to install plugins" "info"
    else
        log "⚠️  TPM clone failed or was skipped" "warn"
        log "  You can install it manually with:" "warn"
        log "    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm" "warn"
    fi
    
    log "" "info"
    log "Repository clone summary:" "info"
    
    local tmux_status="❌ Not cloned"
    local vim_status="❌ Not cloned"
    local tpm_status="❌ Not cloned"
    
    [ -d "$HOME/.tmux/.git" ] && tmux_status="✓ Cloned"
    [ -d "$HOME/.vim/.git" ] && vim_status="✓ Cloned"
    [ -d "$HOME/.tmux/plugins/tpm/.git" ] && tpm_status="✓ Cloned"
    
    log "  tmux: $tmux_status" "info"
    log "  vim:  $vim_status" "info"
    log "  TPM:  $tpm_status" "info"
    
    if ! cd "$original_dir" 2>/dev/null; then
        log "⚠️  Warning: Failed to return to original directory" "warn"
        log "  Current directory: $(pwd)" "warn"
    fi
    
    if [ -d "$HOME/.tmux/.git" ]; then
        return 0
    else
        log "⚠️  Primary repository (tmux) was not successfully cloned" "warn"
        return 1
    fi
}

symlink_external_repos() {
    log "Symlinking external repo configs..." "info"
    
    local errors=0
    
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
# CONFIG FOLDER SYMLINKING
# =============================================================================

symlink_config_folders() {
    log "" "info"
    log "=========================================" "info"
    log "Symlinking Config Folders" "info"
    log "=========================================" "info"
    
    local dotfiles_configs="$DIR/.configs"
    local target_config="$HOME/.config"
    local errors=0
    local linked=0
    local skipped=0
    
    # Validate source directory exists
    if [ ! -d "$dotfiles_configs" ]; then
        log "⚠️ Source directory does not exist: $dotfiles_configs" "warn"
        log "Skipping config folder symlinking" "warn"
        return 0
    fi
    
    # Create ~/.config if it doesn't exist
    if [ ! -d "$target_config" ]; then
        if ! mkdir -p "$target_config" 2>/dev/null; then
            log "❌ Failed to create directory: $target_config" "error"
            return 1
        fi
        log "✓ Created directory: $target_config" "success"
    fi
    
    # Iterate through all items in dotfiles/.configs
    shopt -s nullglob dotglob
    for item in "$dotfiles_configs"/*; do
        [ -e "$item" ] || continue
        
        local basename_item
        basename_item=$(basename "$item")
        local target_path="$target_config/$basename_item"
        
        # Skip if not a directory
        if [ ! -d "$item" ]; then
            log "⚠️ Skipping non-directory: $basename_item" "warn"
            skipped=$((skipped + 1))
            continue
        fi
        
        # Check if target already exists
        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            # If it's already a symlink pointing to our source, skip
            if [ -L "$target_path" ]; then
                local current_target
                if current_target=$(readlink "$target_path" 2>/dev/null); then
                    if [ "$current_target" = "$item" ]; then
                        log "✓ Already linked: $basename_item" "success"
                        linked=$((linked + 1))
                        continue
                    fi
                fi
            fi
            
            # Backup existing file/directory/symlink
            local backup_name="${basename_item}.bak-$DATE"
            local backup_path="$OLD_FILES/$backup_name"
            
            log "Backing up existing: $basename_item -> $backup_name" "info"
            
            if [ -L "$target_path" ]; then
                # If it's a symlink, just remove it
                if ! rm -f "$target_path" 2>/dev/null; then
                    log "❌ Failed to remove existing symlink: $target_path" "error"
                    errors=$((errors + 1))
                    continue
                fi
            else
                # If it's a real file/directory, back it up
                if ! mv "$target_path" "$backup_path" 2>/dev/null; then
                    log "❌ Failed to backup: $basename_item" "error"
                    errors=$((errors + 1))
                    continue
                fi
                log "✓ Backed up: $basename_item" "success"
            fi
        fi
        
        # Create the symlink
        if ln -sf "$item" "$target_path" 2>/dev/null; then
            log "✓ Linked: $basename_item -> $target_config/$basename_item" "success"
            linked=$((linked + 1))
        else
            log "❌ Failed to create symlink: $basename_item" "error"
            errors=$((errors + 1))
        fi
    done
    shopt -u nullglob dotglob
    
    log "" "info"
    log "Config Symlinking Summary:" "info"
    log "  Folders linked: $linked" "info"
    if [ $skipped -gt 0 ]; then
        log "  Items skipped: $skipped" "info"
    fi
    if [ $errors -gt 0 ]; then
        log "  Errors encountered: $errors" "error"
    fi
    
    if [ $linked -eq 0 ] && [ $errors -eq 0 ]; then
        log "⚠️ No config folders found to link in $dotfiles_configs" "warn"
    fi
    
    if [ $errors -gt 0 ]; then
        log "⚠️ $errors error(s) occurred during config folder symlinking" "warn"
        return 1
    fi
    
    return 0
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

source_bashrc() {
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

revert_changes() {
    log "=========================================" "info"
    log "Reverting Dotfiles Installation" "info"
    log "=========================================" "info"
    
    if [ ! -d "$OLD_FILES" ]; then
        log "❌ No backup directory found at: $OLD_FILES" "error"
        log "Nothing to revert." "info"
        return 1
    fi
    
    local reverted=0 failed=0
    
    shopt -s nullglob
    for f in "$OLD_FILES"/*.bak-* "$OLD_FILES"/*.moved-*; do
        [ -f "$f" ] || continue
        local basename_file
        basename_file=$(basename "$f" | sed 's/\.\(bak\|moved\)-.*$//')
        
        if cp -pf "$f" "$HOME/$basename_file" 2>/dev/null; then
            log "✓ Restored: $basename_file" "success"
            reverted=$((reverted + 1))
        else
            log "❌ Failed to restore: $basename_file" "error"
            failed=$((failed + 1))
        fi
    done
    shopt -u nullglob
    
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
    if [ $failed -gt 0 ]; then
        log "  Failed operations: $failed" "error"
    fi
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

show_version() {
    echo -e "${GREEN}${BOLD}RunMe.sh${NC} version ${BLUE}v${VERSION}${NC} (${VERSION_DATE})"
    echo ""
    echo "Dotfiles installer and configuration manager"
    echo "https://github.com/yourusername/dotfiles"
}

show_help() {
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
    echo "    6. Symlinking config folders from ~/.config"
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