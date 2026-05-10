#!/usr/bin/env bash
# =============================================================================
# run_me_first.sh — Dotfiles installer for first-run setup on new systems
# =============================================================================
# Author      : b0red
# Repository  : https://bitbucket.org/b0red/dotfiles
# Version     : 15.7.0
# Date        : 2026-05-11
# Description : Backs up existing dotfiles, creates symlinks, installs apps,
#               updates submodules, and clones companion repos (.tmux, .vim).
# Usage       : ./run_me_first.sh [-h|-?] [--dry-run] [-v] [-d] [-r]
#               [--test-notify] [--notify-only] [--trace]
# Depends     : bash >= 4.0, git, sudo
# =============================================================================

set -euo pipefail

# Clear all aliases to avoid conflicts
unalias -a 2>/dev/null || true

# =============================================================================
# VERSION & CONFIGURATION
# =============================================================================
VERSION="15.6.0"
VERSION_DATE="2026-05-06"

DEBUG=${DEBUG:-0}
TRACE_DEBUG=${TRACE_DEBUG:-0}
DRY_RUN=${DRY_RUN:-0}
CHECK_MODE=${CHECK_MODE:-0}
SLEEP=${SLEEP:-2}
DIR="$HOME/.dotfiles"
OLD_FILES="$DIR/oldfiles"
LOG_DIR="$DIR/logs"
STATE_FILE="$DIR/.installation-state"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
TITLE="Dotfiles Installer Script"
DOT_ARRAY=("$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.inputrc")
OLD_FILE_ARRAY=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.inputrc" "$HOME/.cshrc" "$HOME/.login")
TEMP_FILES=()
APP_SELECTION_MODE="all"      # all, selected, none
INTERACTIVE_APP_SELECTION=${INTERACTIVE_APP_SELECTION:-0}
SKIP_APP_INSTALL=${SKIP_APP_INSTALL:-0}
BACKUP_MANIFEST="$OLD_FILES/backup-manifest-$DATE.txt"

# Standard exit codes (Vibecoding v5.6)
EXIT_OK=0
EXIT_ERROR=1
EXIT_ENV=2
EXIT_ABORT=3
EXIT_MISSING=4
EXIT_PERM=5

# Colours — source shared include if available, else inline fallback
if [ -f "$DIR/ColorCodes.inc" ]; then
    # shellcheck source=/dev/null
    . "$DIR/ColorCodes.inc"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
fi

# =============================================================================
# RECURSION GUARD
# =============================================================================
if [ -n "${RUNME_INITIATED:-}" ]; then
    echo -e "${RED}run_me_first.sh already running (PID $$)${NC}" >&2
    exit $EXIT_ERROR
fi
RUNME_INITIATED=1
export RUNME_INITIATED

# =============================================================================
# STATE & VALIDATION FUNCTIONS
# =============================================================================

check_installation_state() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1  # Fresh install
    fi
    cat "$STATE_FILE"
}

validate_installation() {
    local issues=0
    
    log_info ""
    log_info "Validating installation state..."
    
    # Check symlinks
    for src in "${DOT_ARRAY[@]}"; do
        if [ ! -L "$src" ]; then
            log_warning "  ⚠️  Symlink missing: $src"
            issues=$((issues + 1))
        fi
    done
    
    # Check external repos
    if [ ! -d "$HOME/.tmux/.git" ]; then
        log_warning "  ⚠️  Tmux repo not linked: ~/.tmux"
        issues=$((issues + 1))
    fi
    
    if [ ! -d "$HOME/.vim/.git" ]; then
        log_warning "  ⚠️  Vim repo not linked: ~/.vim"
        issues=$((issues + 1))
    fi
    
    # Check submodules
    if [ -d "$DIR/.git" ]; then
        if ! git -C "$DIR" submodule foreach --quiet 'test -d .git' 2>/dev/null; then
            log_warning "  ⚠️  Git submodules not initialized"
            issues=$((issues + 1))
        fi
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "✓ All validations passed"
        return 0
    else
        log_warning "⚠️  Found $issues issue(s)"
        return 1
    fi
}

update_installation_state() {
    mkdir -p "$DIR"
    cat > "$STATE_FILE" << EOF
LAST_RUN=$(date +%Y-%m-%d_%H:%M:%S)
VERSION=$VERSION
COMPLETED_STEPS=backup,symlink,apps,submodules,repos,config_folders
EOF
    log_success "✓ Installation state recorded"
}

check_mode() {
    log_info ""
    log_info "Installation Status Check"
    log_info "========================================="
    
    local state
    state=$(check_installation_state)
    
    if [ -z "$state" ]; then
        log_info "📌 Status: Fresh installation (no previous run)"
    else
        log_info "📌 Status: Installation detected"
        log_info ""
        log_info "$state" | while IFS='=' read -r key value; do
            case "$key" in
                LAST_RUN)
                    log_info "   Last run: $value"
                    ;;
                VERSION)
                    log_info "   Version: $value"
                    ;;
                COMPLETED_STEPS)
                    log_info "   Completed steps: ${value//,/, }"
                    ;;
            esac
        done
    fi
    
    log_info ""
    if validate_installation; then
        log_success "✓ All checks passed — setup appears complete"
        log_info ""
        read -rp "Re-run full installation? ([y]es or [N]o): " reply
        case $(echo "$reply" | tr '[:upper:]' '[:lower:]') in
            y|yes)
                log_info "Proceeding with full installation..."
                return 0
                ;;
            *)
                log_info "Exiting (no changes made)"
                exit 0
                ;;
        esac
    else
        log_warning "Issues detected. Running full installation to fix..."
        return 0
    fi
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================
main() {
    if [ "${CHECK_MODE:-0}" -eq 1 ]; then
        logfile_init
        check_mode
    fi
    
    logfile_init
    log_info "========================================="
    log_info "Starting Dotfiles Installation"
    log_info "Version: v${VERSION} (${VERSION_DATE})"
    log_info "========================================="
    
    if [ "${TRACE_DEBUG:-0}" -eq 1 ]; then
        set -x
        trap 'read -p "DEBUG: Press Enter..."' DEBUG
        log_success "✓ Trace enabled"
    fi
    
    get_os_info
    validate_environment
    load_package_functions || log_warning "⚠️ Continuing without package functions"
    if [ "${SKIP_APP_INSTALL:-0}" -eq 0 ]; then
        load_app_list || log_warning "⚠️ Using fallback app list"
    else
        log_info "Application installation will be skipped"
    fi

    # Prompt for sudo early
    log_info ""
    log_info "🔐 Checking sudo access (you may be prompted for password)..."
    if ! sudo -v; then
        log_error "❌ Sudo access required for package installation"
        log_error "Run 'sudo -v' to verify sudo access, then try again."
        exit $EXIT_PERM
    fi
    log_success "✓ Sudo access verified"
    log_info ""
    
    backup_dotfiles
    cleanup_symlinks
    symlink_dotfiles
    install_apps
    setup_taskwarrior_config
    archive_backup
    update_submodules
    clone_repos
    symlink_external_repos
    symlink_config_folders
    source_bashrc
    
    log_info ""
    log_success "========================================="
    log_success "✓ Installation Complete!"
    log_success "========================================="
    log_info "Log saved to: $LOG"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Restart your shell: exec bash"
    log_info "  2. Or reload config: reload"
    log_info "  3. Test package functions: version"
    log_info "  4. Check for warnings above"
    log_info ""
    log_info "For troubleshooting, see: README.md"
    log_info "To revert changes: ./run_me_first.sh --revert"
    log_success "========================================="
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

_log_write() {
    local prefix="$1" msg="$2"
    [ -n "${LOG:-}" ] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${prefix}: ${msg}" >> "$LOG" 2>/dev/null || true
}

log_error() {
    local msg="$1"
    echo -e "${RED}${msg}${NC}" >&2
    _log_write "ERROR" "$msg"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}${msg}${NC}"
    _log_write "OK" "$msg"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}${msg}${NC}"
    _log_write "WARN" "$msg"
}

log_info() {
    local msg="$1"
    echo -e "${YELLOW}${msg}${NC}"
    _log_write "INFO" "$msg"
}

log_debug() {
    [ "${DEBUG:-0}" -eq 1 ] || return 0
    local msg="$1"
    echo -e "${BLUE}[DEBUG] ${msg}${NC}"
    _log_write "DEBUG" "$msg"
}

safe_exec() {
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_info "  [dry-run] $*"
        return 0
    fi
    "$@"
}

backup_manifest_init() {
    if [ ! -d "$OLD_FILES" ]; then
        mkdir -p "$OLD_FILES" 2>/dev/null || return 1
    fi
    touch "$BACKUP_MANIFEST" 2>/dev/null || return 1
}

record_backup() {
    local original="$1" backup="$2"
    if [ -z "$original" ] || [ -z "$backup" ]; then
        return 1
    fi
    printf '%s|%s\n' "$original" "$backup" >> "$BACKUP_MANIFEST"
}

backup_target() {
    local src="$1"
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        return 0
    fi
    if [ -z "$BACKUP_MANIFEST" ]; then
        return 1
    fi
    if [ ! -f "$BACKUP_MANIFEST" ]; then
        backup_manifest_init || true
    fi
    local rel="${src#$HOME}"
    local backup_path="$OLD_FILES${rel}.bak-$DATE"
    mkdir -p "$(dirname "$backup_path")" 2>/dev/null || return 1
    if safe_exec cp -a "$src" "$backup_path"; then
        record_backup "$src" "$backup_path"
        return 0
    fi
    return 1
}

restore_backup_manifest() {
    local manifest
    manifest=$(ls -1t "$OLD_FILES"/backup-manifest-*.txt 2>/dev/null | head -n1 || true)
    if [ -z "$manifest" ]; then
        return 1
    fi
    log_info "Restoring backups from manifest: $manifest"
    while IFS='|' read -r original backup; do
        [ -z "$original" ] && continue
        if [ ! -e "$backup" ] && [ ! -L "$backup" ]; then
            log_warning "⚠️ Backup missing: $backup"
            continue
        fi
        if [ -e "$original" ] || [ -L "$original" ]; then
            rm -rf "$original" 2>/dev/null || log_warning "⚠️ Could not remove existing $original"
        fi
        mkdir -p "$(dirname "$original")" 2>/dev/null || log_warning "⚠️ Could not create directory: $(dirname "$original")"
        if cp -a "$backup" "$original" 2>/dev/null; then
            log_success "✓ Restored: $original"
        else
            log_error "❌ Failed to restore: $original"
        fi
    done < "$manifest"
    return 0
}

logfile_init() {
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo -e "${RED}❌ Failed to create log directory: $LOG_DIR${NC}" >&2
        exit $EXIT_PERM
    fi
    
    LOG="$LOG_DIR/install-$DATE.log"
    
    if ! echo "[$(date +'%Y-%m-%d %H:%M:%S')] $TITLE started (PID $$)" > "$LOG" 2>/dev/null; then
        echo -e "${RED}❌ Failed to initialize log file: $LOG${NC}" >&2
        exit $EXIT_PERM
    fi
    
    if [ -t 1 ]; then
        log_success "🎨 Color output enabled"
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
        log_error "❌ check_or_add_line: Invalid arguments"
        return 1
    fi
    
    # Check if file is a symlink
    if [[ -L "$file" ]]; then
        log_warning "⚠️ Skipping $file (symlink to repo)"
        return 0
    fi
    
    # Create file if it doesn't exist
    if [[ ! -f "$file" ]]; then
        if ! touch "$file" 2>/dev/null; then
            log_error "❌ Failed to create $file"
            return 1
        fi
        log_info "Created empty $file"
    fi
    
    # Check if line already exists, if not add it
    if grep -qxF "$line" "$file" 2>/dev/null; then
        log_info "Line already exists in $file"
    else
        if ! printf '%s\n' "$line" >> "$file" 2>/dev/null; then
            log_error "❌ Failed to add line to $file"
            return 1
        fi
        log_success "Added line to $file"
    fi
    
    return 0
}

add_file_header() {
    local target_file="$1"
    local creation_date
    creation_date="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="${HOSTNAME:-$(hostname)}"
    
    if [ -z "$target_file" ]; then
        log_error "❌ add_file_header: No target file specified"
        return 1
    fi
    
    if [ ! -f "$target_file" ]; then
        log_warning "⚠️ Target file does not exist: $target_file"
        return 1
    fi
    
    local temp_file
    if ! temp_file=$(mktemp 2>/dev/null); then
        log_error "❌ Failed to create temp file"
        return 1
    fi
    TEMP_FILES+=("$temp_file")
    
    # Step 1: Check for shebang on line 1
    local shebang=""
    local first_line
    first_line=$(head -n 1 "$target_file")
    if [[ "$first_line" =~ ^#! ]]; then
        shebang="$first_line"
    fi
    
    # Step 2: Find where actual content starts (after shebang and old header)
    local content_start_line=1
    
    # If shebang exists, content is at least line 2
    if [ -n "$shebang" ]; then
        content_start_line=2
    fi
    
    # Check if there's an old run_me_first.sh header to skip
    if grep -q "Created by run_me_first.sh" "$target_file" 2>/dev/null; then
        log_info "Updating header in $(basename "$target_file")..."
        
        # Read file line by line starting after shebang
        local line_num=$content_start_line
        local found_header_end=0
        
        while IFS= read -r line; do
            # Check if this line is part of the header
            if [[ "$line" =~ ^###.*-\+- ]] || \
               [[ "$line" =~ ^###.*Created\ by\ RunMe\.sh ]] || \
               [[ "$line" =~ ^###.*Host: ]] || \
               [[ "$line" =~ ^###.*User: ]] || \
               [[ "$line" =~ ^###.*Distro: ]]; then
                # Still in header, skip it
                line_num=$((line_num + 1))
                continue
            elif [[ "$line" =~ ^[[:space:]]*$ ]] && [ $found_header_end -eq 0 ]; then
                # Empty line right after header
                line_num=$((line_num + 1))
                found_header_end=1
                break
            else
                # Found actual content
                break
            fi
        done < <(tail -n +$content_start_line "$target_file")
        
        content_start_line=$line_num
    else
        log_info "Adding header to $(basename "$target_file")..."
    fi
    
    # Step 3: Build the new file
    {
        # Write shebang if original had one
        if [ -n "$shebang" ]; then
            echo "$shebang"
        fi
        
        # Write new header
        cat << EOF
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by run_me_first.sh $creation_date
###                                             Host: $hostname
###                                             User: ${USER:-$(whoami)}
###                                             Distro: $DISTRO
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

EOF
        
        # Write content starting from where header ends
        tail -n +$content_start_line "$target_file"
        
    } > "$temp_file"
    
    # Step 4: Replace original file — either mv consumes it or we remove it
    if mv "$temp_file" "$target_file" 2>/dev/null; then
        TEMP_FILES=("${TEMP_FILES[@]/$temp_file}")
        log_success "✓ Header updated in $(basename "$target_file")"
        return 0
    else
        log_error "❌ Failed to update header in $(basename "$target_file")"
        rm -f "$temp_file"
        TEMP_FILES=("${TEMP_FILES[@]/$temp_file}")
        return 1
    fi
}

cleanup_on_exit() {
    local exit_code=$?
    local f
    for f in "${TEMP_FILES[@]:-}"; do
        rm -f "$f" 2>/dev/null || true
    done
    if [ "$exit_code" -eq "${EXIT_ABORT:-3}" ]; then
        echo -e "${RED:-}⚠️  Installation interrupted${NC:-}" >&2
    elif [ "$exit_code" -ne 0 ]; then
        echo -e "${RED:-}❌ Exited with code $exit_code${NC:-}" >&2
    fi
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
                                    log_warning "Warning: Linux distribution '$distro' is not officially supported."
                                    ;;
                            esac
                        else
                            DISTRO="$distro"
                            DISTRO_BASE="linux"
                            log_warning "Warning: Linux distribution '$distro' is not officially supported."
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
                    log_warning "Warning: Cannot determine Linux distribution"
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
            log_warning "Warning: Operating system '$os' is not recognized"
            ;;
    esac
    
    export OS="$os" KERNEL="$kernel" MACH="$mach" DISTRO DISTRO_BASE
    log_info "Detected: OS=$OS, Distro=$DISTRO, Base=$DISTRO_BASE, Kernel=$KERNEL, Arch=$MACH"
}

validate_environment() {
    log_info "🔍 Validating environment..."
    local errors=0

    if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
        log_error "❌ Bash 4.0+ required (found: ${BASH_VERSION:-unknown})"
        errors=$((errors + 1))
    fi

    if ! command -v git >/dev/null 2>&1; then
        log_error "❌ git is required but not installed"
        errors=$((errors + 1))
    fi

    if [ -z "${HOME:-}" ] || [ ! -d "${HOME}" ]; then
        log_error "❌ \$HOME is not set or is not a valid directory"
        errors=$((errors + 1))
    fi

    if [ ! -d "$DIR" ]; then
        log_error "❌ Dotfiles directory not found: $DIR"
        log_error "   Clone the repo first:"
        log_error "   git clone git@bitbucket.org:b0red/dotfiles.git $DIR"
        errors=$((errors + 1))
    fi

    if [ "$errors" -gt 0 ]; then
        log_error "❌ Environment validation failed ($errors error(s)) — aborting"
        exit $EXIT_ENV
    fi

    log_success "✓ Environment OK"
}

# =============================================================================
# APPLICATION LIST MANAGEMENT
# =============================================================================

load_app_list() {
    local app_file="$DIR/.install_apps.inc"
    
    if [ ! -r "$app_file" ]; then
        log_warning "⚠️ Warning: $app_file not found"
        log_warning "Using fallback app list"
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
        log_warning "⚠️ No apps found in $app_file"
        return 1
    fi
    
    APP_ARRAY=("${apps[@]}")
    log_success "✓ Loaded ${#APP_ARRAY[@]} applications from $app_file"
    return 0
}

# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

load_package_functions() {
    local pkg_file="$DIR/.bashrc.d/pkg_aliases.bash"
    
    if [ ! -r "$pkg_file" ]; then
        log_warning "⚠️ Warning: $pkg_file not found or not readable"
        return 1
    fi
    
    log_info "Loading package management functions from $pkg_file..."
    
    export DISTROBASE="$DISTRO_BASE"
    
    # shellcheck disable=SC1090
    source "$pkg_file"
    
    log_success "✓ Package file sourced"
    
    log_info "Calling set_package_aliases for distro: $DISTRO_BASE..."
    
    if set_package_aliases 2>&1 | tee -a "$LOG"; then
        log_success "✅ Package functions configured for $DISTRO_BASE"
    else
        log_error "❌ set_package_aliases failed"
        return 1
    fi
    
    local missing_funcs=()
    for func in p_install p_remove p_update p_upgrade p_search; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            missing_funcs+=("$func")
        fi
    done
    
    if [ ${#missing_funcs[@]} -gt 0 ]; then
        log_warning "⚠️ Some functions missing: ${missing_funcs[*]}"
        return 1
    fi
    
    log_success "✅ All package functions verified"
    return 0
}

# =============================================================================
# APPLICATION INSTALLATION
# =============================================================================

install_apps() {
    log_info "Installing applications..."

    if [ "${SKIP_APP_INSTALL:-0}" -eq 1 ]; then
        log_info "Skipping application installation by request"
        return 0
    fi

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_info "  [dry-run] would install ${#APP_ARRAY[@]:-0} apps via package manager"
        return 0
    fi

    if [ "${INTERACTIVE_APP_SELECTION:-0}" -eq 1 ]; then
        prompt_select_apps
    fi

    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log_info "No applications selected for installation"
        return 0
    fi
    
    log_info "Processing ${#APP_ARRAY[@]} applications..."
    
    if ! declare -f p_install >/dev/null 2>&1; then
        log_warning "⚠️ 'p_install' function not available, using install_apps_direct"
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
            log_success "✅ $app already installed (found: $check_cmd)"
            skipped=$((skipped + 1))
            continue
        fi
        
        log_info "Installing $app..."
        
        if p_install "$app" 2>&1 | tee -a "$LOG"; then
            log_success "✅ Installed $app"
            installed=$((installed + 1))
        else
            log_error "❌ Failed to install $app"
            failed=$((failed + 1))
        fi
        
        sleep 0.5
    done
    
    log_info ""
    log_info "Installation summary: $installed installed, $skipped skipped, $failed failed"
    if [ $failed -gt 0 ]; then
        return 1
    fi
    return 0
}

prompt_select_apps() {
    if [ "${INTERACTIVE_APP_SELECTION:-0}" -ne 1 ]; then
        return 0
    fi
    if [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log_warning "⚠️ No applications available to select"
        return 0
    fi

    log_info "Interactive application selection enabled"
    while true; do
        echo ""
        log_info "Pick packages to install from .install_apps.inc:"
        for i in "${!APP_ARRAY[@]}"; do
            printf "  %2d) %s\n" "$((i + 1))" "${APP_ARRAY[i]}"
        done
        echo ""
        read -rp "Enter numbers separated by commas, 'all' to install all, or 'none' to skip: " selection
        selection="${selection// /}"
        selection="$(echo "$selection" | tr '[:upper:]' '[:lower:]')"
        if [ -z "$selection" ] || [ "$selection" = "all" ]; then
            log_info "Installing all listed packages"
            break
        fi
        if [ "$selection" = "none" ] || [ "$selection" = "skip" ]; then
            APP_ARRAY=()
            log_warning "Skipping all app installs"
            break
        fi
        local valid=1
        local selected=()
        IFS=',' read -ra entries <<< "$selection"
        for entry in "${entries[@]}"; do
            if [[ "$entry" =~ ^[0-9]+$ ]] && [ "$entry" -ge 1 ] && [ "$entry" -le "${#APP_ARRAY[@]}" ]; then
                selected+=("${APP_ARRAY[entry-1]}")
            else
                log_warning "⚠️ Invalid selection: $entry"
                valid=0
                break
            fi
        done
        if [ $valid -eq 1 ]; then
            local unique=()
            for app in "${selected[@]}"; do
                if ! printf '%s\n' "${unique[@]}" | grep -Fxq "$app" 2>/dev/null; then
                    unique+=("$app")
                fi
            done
            APP_ARRAY=("${unique[@]}")
            log_info "Selected ${#APP_ARRAY[@]} app(s) for installation"
            break
        fi
    done
}

install_apps_direct() {
    log_info "Installing applications (direct package manager)..."
    
    if [ -z "${APP_ARRAY+x}" ] || [ ${#APP_ARRAY[@]} -eq 0 ]; then
        log_error "❌ APP_ARRAY not loaded or empty"
        return 1
    fi
    
    log_info "Processing ${#APP_ARRAY[@]} applications..."
    
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
            log_error "❌ Unknown distro: $DISTRO_BASE"
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
            log_success "✅ $app already installed (found: $check_cmd)"
            skipped=$((skipped + 1))
            continue
        fi
        
        log_info "Installing $app..."
        if $pkg_install "$app" 2>&1 | tee -a "$LOG"; then
            log_success "✅ Installed $app"
            installed=$((installed + 1))
        else
            log_error "❌ Failed to install $app"
            failed=$((failed + 1))
        fi
        
        sleep 0.5
    done
    
    log_info ""
    log_info "Installation summary: $installed installed, $skipped skipped, $failed failed"
    if [ $failed -gt 0 ]; then
        return 1
    fi
    return 0
}

setup_taskwarrior_config() {
    log_info "Checking for Taskwarrior configuration..."

    local taskrc="$HOME/.taskrc"
    local repo_taskrc="$DIR/taskwarrior/.taskrc"

    if [ ! -f "$taskrc" ]; then
        log_info "⏭️  ~/.taskrc not found, skipping Taskwarrior config setup"
        return 0
    fi

    log_info "Found existing ~/.taskrc, setting up dotfiles version..."

    # Create taskwarrior directory in repo if it doesn't exist
    if [ ! -d "$DIR/taskwarrior" ]; then
        if ! mkdir -p "$DIR/taskwarrior"; then
            log_error "❌ Failed to create $DIR/taskwarrior"
            return 1
        fi
    fi

    # Backup existing repo file if it exists
    if [ -f "$repo_taskrc" ]; then
        local backup_file="$OLD_FILES/taskwarrior_$(date +%Y%m%d_%H%M%S).taskrc"
        if cp "$repo_taskrc" "$backup_file"; then
            log_info "✓ Backed up existing repo .taskrc to $backup_file"
        else
            log_warning "⚠️ Failed to backup existing repo .taskrc"
        fi
    fi

    # Copy current .taskrc to repo
    if cp "$taskrc" "$repo_taskrc"; then
        log_success "✓ Copied ~/.taskrc to $repo_taskrc"
    else
        log_error "❌ Failed to copy ~/.taskrc to repo"
        return 1
    fi

    # Backup current .taskrc if needed
    if backup_target "$taskrc"; then
        log_info "✓ Backed up existing ~/.taskrc"
    fi

    # Create symlink
    if safe_exec ln -sf "$repo_taskrc" "$taskrc"; then
        log_success "✓ Symlinked: $repo_taskrc -> $taskrc"
    else
        log_error "❌ Failed to symlink Taskwarrior config"
        return 1
    fi

    return 0
}

# =============================================================================
# BACKUP & SYMLINK MANAGEMENT
# =============================================================================

backup_dotfiles() {
    log_info "Backing up existing dotfiles..."

    if ! mkdir -p "$OLD_FILES" 2>/dev/null; then
        log_error "❌ Failed to create backup directory"
        exit $EXIT_PERM
    fi
    backup_manifest_init || log_warning "⚠️ Could not initialize backup manifest"

    local backed_up=0 skipped_unchanged=0

    for f in "${OLD_FILE_ARRAY[@]}"; do
        if [ -e "$f" ] || [ -L "$f" ]; then
            if [ -f "$f" ] && [ ! -L "$f" ] && [ -f "$DIR/$(basename "$f")" ] && cmp -s "$f" "$DIR/$(basename "$f")" 2>/dev/null; then
                log_info "⏭️  Skipping $f (unchanged from repo)"
                skipped_unchanged=$((skipped_unchanged + 1))
                continue
            fi
            if backup_target "$f"; then
                backed_up=$((backed_up + 1))
            fi
        fi
    done

    if [ $backed_up -eq 0 ]; then
        if [ $skipped_unchanged -gt 0 ]; then
            log_info "No new backups needed ($skipped_unchanged files unchanged)"
        else
            log_info "No files to backup"
        fi
    else
        log_success "Backed up $backed_up files to $OLD_FILES/"
        if [ $skipped_unchanged -gt 0 ]; then
            log_info "Skipped $skipped_unchanged unchanged files"
        fi
    fi
}

cleanup_symlinks() {
    log_info "Cleaning up old symlinks..."
    backup_manifest_init || log_warning "⚠️ Could not initialize backup manifest"

    for file in "${DOT_ARRAY[@]}"; do
        if [ -L "$file" ]; then
            if [ ! -e "$file" ]; then
                if rm -f "$file" 2>/dev/null; then
                    log_success "✓ Removed broken symlink: $file"
                else
                    log_error "❌ Failed to remove broken symlink: $file"
                fi
            else
                if backup_target "$file"; then
                    if rm -rf "$file" 2>/dev/null; then
                        log_success "✓ Backed up and removed existing symlink: $file"
                    else
                        log_error "❌ Failed to remove: $file"
                    fi
                fi
            fi
        elif [ -e "$file" ]; then
            if backup_target "$file"; then
                if rm -rf "$file" 2>/dev/null; then
                    log_success "✓ Backed up and removed existing file: $file"
                else
                    log_error "❌ Failed to remove: $file"
                fi
            fi
        fi
    done
}

symlink_dotfiles() {
    log_info "Creating symlinks..."
    
    if [ ! -d "$DIR" ]; then
        log_error "❌ Error: $DIR not found. Clone repo first."
        exit $EXIT_MISSING
    fi
    
    local linked=0
    for src in "${DOT_ARRAY[@]}"; do
        local target
        target="$DIR/$(basename "$src")"
        if [ ! -f "$target" ]; then
            log_warning "⚠️ Warning: $target not found, skipping $(basename "$src")"
            continue
        fi

        if [ -e "$src" ] || [ -L "$src" ]; then
            if ! safe_exec rm -f "$src"; then
                log_error "❌ Failed to remove: $src"
                continue
            fi
        fi

        if safe_exec ln -sf "$target" "$src"; then
            log_success "✓ Linked: $target -> $src"
            linked=$((linked + 1))
        else
            log_error "❌ Failed to link: $src"
        fi
    done
    log_success "Created $linked symlinks"
    
    log_info "Managing file headers..."
    if [ -f "$DIR/.bashrc" ]; then add_file_header "$DIR/.bashrc"; fi
    if [ -f "$DIR/.profile" ]; then add_file_header "$DIR/.profile"; fi
    if [ -f "$DIR/.bash_profile" ]; then add_file_header "$DIR/.bash_profile"; fi
    
    if [ -x "$DIR/symlink.sh" ]; then
        log_info "Running distro-specific symlink script..."
        if "$DIR/symlink.sh" "$DISTRO" "$DISTRO_BASE" 2>&1 | tee -a "$LOG"; then
            log_success "✓ Distro-specific symlinks created"
        else
            log_warning "⚠️ Distro-specific symlink script encountered issues"
        fi
    else
        log_warning "⚠️ symlink.sh not found or not executable"
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
                log_success "✓ Added .bashrc loader to .bash_profile (in repo)"
            else
                log_error "❌ Failed to add .bashrc loader"
            fi
        else
            log_success "✓ .bash_profile already sources .bashrc"
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
            log_success "✓ Archived backups: $archived"
            cleanup_old_archives
        else
            log_warning "⚠️ Failed to create archive"
            return 1
        fi
    else
        log_info "No files to archive"
    fi
}

cleanup_old_archives() {
    log_info "Cleaning up old backup archives (keeping 3 most recent)..."
    
    shopt -s nullglob
    local archives=("$DIR"/backup-*-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].tar.gz)
    shopt -u nullglob
    
    local count=${#archives[@]}
    
    if [ $count -le 3 ]; then
        log_info "Keeping all $count archive(s) (3 or fewer exist)"
        return 0
    fi
    
    local to_delete=$((count - 3))
    local deleted=0
    local old_archives
    mapfile -t old_archives < <(ls -t "$DIR"/backup-*-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].tar.gz 2>/dev/null | tail -n $to_delete)
    
    for archive in "${old_archives[@]}"; do
        if [ -f "$archive" ]; then
            if rm -f "$archive" 2>/dev/null; then
                log_info "🗑️  Deleted old archive: $(basename "$archive")"
                deleted=$((deleted + 1))
            else
                log_warning "⚠️  Failed to delete: $(basename "$archive")"
            fi
        fi
    done
    
    if [ $deleted -gt 0 ]; then
        log_success "✓ Cleaned up $deleted old archive(s), kept 3 most recent"
    else
        log_info "No old archives to clean up"
    fi
}

update_submodules() {
    log_info "Updating git submodules..."

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_info "  [dry-run] would run: git submodule update --init --recursive"
        return 0
    fi

    if [ ! -d "$DIR/.git" ]; then
        log_warning "⚠️ Not a git repository, skipping submodules"
        return 0
    fi
    
    if ! cd "$DIR" 2>/dev/null; then
        log_error "❌ Failed to cd to $DIR"
        return 1
    fi
    
    if git submodule update --init --recursive 2>&1 | tee -a "$LOG"; then
        git submodule foreach --recursive 'git pull origin master || git pull origin main' 2>&1 | tee -a "$LOG" || true
        log_success "✓ Updated submodules"
    else
        log_warning "⚠️ No submodules found or update failed"
    fi
}

# =============================================================================
# REPO SYMLINKING (tmux + vim now live inside this repo as subtrees)
# =============================================================================

clone_repos() {
    log_info "Linking tmux and vim configs from repo..."

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_info "  [dry-run] would link: $DIR/tmux -> ~/.tmux"
        log_info "  [dry-run] would link: $DIR/vim  -> ~/.vim"
        return 0
    fi

    local errors=0

    _link_repo_dir() {
        local src="$1" dest="$2" label="$3"
        if [ ! -d "$src" ]; then
            log_error "❌ Source directory not found: $src"
            return 1
        fi
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            log_warning "⚠️  $dest exists and is not a symlink — backing up"
            if backup_target "$dest"; then
                rm -rf "$dest" 2>/dev/null || true
            fi
        fi
        if safe_exec ln -sfn "$src" "$dest"; then
            log_success "✓ Linked: $src -> $dest"
            return 0
        else
            log_error "❌ Failed to link $label"
            return 1
        fi
    }

    _link_repo_dir "$DIR/tmux" "$HOME/.tmux" "tmux" || errors=$((errors + 1))
    _link_repo_dir "$DIR/vim"  "$HOME/.vim"  "vim"  || errors=$((errors + 1))

    log_info ""
    log_info "Repo link summary:"
    [ -L "$HOME/.tmux" ] && log_success "  tmux   : ✓ Linked ($DIR/tmux)" \
                         || log_warning  "  tmux   : ❌ Not linked"
    [ -L "$HOME/.vim"  ] && log_success "  vim    : ✓ Linked ($DIR/vim)"  \
                         || log_warning  "  vim    : ❌ Not linked"
    log_success "  Coffee : ✓ Plugin config path available (tmux/coffee/plugins)"

    return $errors
}

# --- dead code preserved for reference during migration ---
_clone_if_missing_UNUSED() {
        local repo_url="$1"
        local target_dir="$2"
        local repo_name
        repo_name=$(basename "$target_dir")
        
        if [ -z "$repo_url" ]; then
            log_error "❌ clone_if_missing: No repository URL provided"
            return 1
        fi
        
        if [ -z "$target_dir" ]; then
            log_error "❌ clone_if_missing: No target directory provided"
            return 1
        fi
        
        if [ -e "$target_dir" ]; then
            if [ -d "$target_dir/.git" ]; then
                log_success "✓ $repo_name exists and is a git repo"
                
                local current_remote
                current_remote=$(git -C "$target_dir" config --get remote.origin.url 2>/dev/null || echo "")
                
                if [ -n "$current_remote" ]; then
                    local normalized_current normalized_expected
                    normalized_current=$(echo "$current_remote" | sed 's/\.git$//' | tr '[:upper:]' '[:lower:]')
                    normalized_expected=$(echo "$repo_url" | sed 's/\.git$//' | tr '[:upper:]' '[:lower:]')
                    
                    if [[ "$normalized_current" == "$normalized_expected" ]] || \
                       [[ "$normalized_current" == *"${normalized_expected##*/}" ]] || \
                       [[ "$normalized_expected" == *"${normalized_current##*/}" ]]; then
                        log_info "  Remote URL matches expected repository"
                    else
                        log_warning "⚠️  Warning: Remote URL differs from expected"
                        log_warning "  Current:  $current_remote"
                        log_warning "  Expected: $repo_url"
                    fi
                else
                    log_warning "⚠️  Warning: Could not verify remote URL"
                fi
                
                if git -C "$target_dir" diff-index --quiet HEAD -- 2>/dev/null; then
                    log_info "  Repository is clean (no uncommitted changes)"
                else
                    log_warning "⚠️  Repository has uncommitted changes"
                fi
                
                return 0
            else
                log_warning "⚠️  $target_dir exists but is not a git repository"
                log_warning "  Skipping clone to avoid overwriting existing directory"
                log_warning "  To fix: mv $target_dir ${target_dir}.backup && re-run script"
                return 1
            fi
        fi
        
        log_info "Cloning $repo_name repository..."
        log_info "  Source: $repo_url"
        log_info "  Target: $target_dir"
        
        if GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules "$repo_url" "$target_dir" 2>&1 | tee -a "$LOG"; then
            log_success "✓ Successfully cloned $repo_name"
            
            if [ -d "$target_dir/.git" ]; then
                log_success "  ✓ Git repository structure verified"
                
                if [ -f "$target_dir/.gitmodules" ]; then
                    log_info "  Repository contains submodules"
                    
                    if git -C "$target_dir" submodule status 2>/dev/null | grep -q '^-'; then
                        log_warning "⚠️  Some submodules may not be initialized"
                        log_info "  Initializing submodules..."
                        if git -C "$target_dir" submodule update --init --recursive 2>&1 | tee -a "$LOG"; then
                            log_success "  ✓ Submodules initialized"
                        else
                            log_warning "  ⚠️  Failed to initialize some submodules"
                        fi
                    else
                        log_success "  ✓ Submodules initialized"
                    fi
                fi
                
                return 0
            else
                log_error "❌ Clone appeared to succeed but git directory not found"
                return 1
            fi
        else
            local exit_code=$?
            log_error "❌ Failed to clone $repo_name (exit code: $exit_code)"
            
            case $exit_code in
                128)
                    log_error "  Common causes:"
                    log_error "    • Repository URL is incorrect"
                    log_error "    • No network connectivity"
                    log_error "    • SSH key not configured (for git@ URLs)"
                    log_error "    • Repository doesn't exist or is private"
                    ;;
                *)
                    log_error "  Check network connectivity and repository access"
                    ;;
            esac
            
            if [ -d "$target_dir" ] && [ ! -d "$target_dir/.git" ]; then
                log_warning "  Cleaning up incomplete clone directory..."
                if rm -rf "$target_dir" 2>/dev/null; then
                    log_success "  ✓ Cleaned up incomplete directory"
                else
                    log_warning "  ⚠️  Failed to clean up $target_dir"
                fi
            fi
            
            return 1
        fi
} # end _clone_if_missing_UNUSED

symlink_external_repos() {
    log_info "Symlinking external repo configs..."
    
    local errors=0
    
    if [ -d "$HOME/.tmux" ]; then
        if [ -f "$HOME/.tmux/.tmux.conf" ]; then
            if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
                if backup_target "$HOME/.tmux.conf"; then
                    rm -f "$HOME/.tmux.conf" 2>/dev/null || true
                fi
            fi
            if [ $errors -eq 0 ]; then
                if safe_exec ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"; then
                    log_success "✓ Linked: ~/.tmux/.tmux.conf -> ~/.tmux.conf"
                else
                    log_error "❌ Failed to link .tmux.conf"
                    errors=$((errors + 1))
                fi
            fi
        else
            log_warning "⚠️ ~/.tmux/.tmux.conf not found, skipping"
        fi
    else
        log_warning "⚠️ ~/.tmux directory not found, skipping .tmux.conf symlink"
    fi
    
    if [ -d "$HOME/.vim" ]; then
        if [ -f "$HOME/.vim/.vimrc" ]; then
            if [ -e "$HOME/.vimrc" ] || [ -L "$HOME/.vimrc" ]; then
                if backup_target "$HOME/.vimrc"; then
                    rm -f "$HOME/.vimrc" 2>/dev/null || true
                fi
            fi
            if safe_exec ln -sf "$HOME/.vim/.vimrc" "$HOME/.vimrc"; then
                log_success "✓ Linked: ~/.vim/.vimrc -> ~/.vimrc"
            else
                log_error "❌ Failed to link .vimrc"
                errors=$((errors + 1))
            fi
        else
            log_warning "⚠️ ~/.vim/.vimrc not found, skipping"
        fi
    else
        log_warning "⚠️ ~/.vim directory not found, skipping .vimrc symlink"
    fi
    
    if [ $errors -gt 0 ]; then
        log_warning "⚠️ $errors error(s) occurred during external repo symlinking"
        return 1
    fi
    return 0
}

# =============================================================================
# CONFIG FOLDER SYMLINKING
# =============================================================================

symlink_config_folders() {
    log_info ""
    log_info "========================================="
    log_info "Symlinking Config Folders"
    log_info "========================================="
    
    local dotfiles_configs="$DIR/.configs"
    local target_config="$HOME/.config"
    local errors=0
    local linked=0
    local skipped=0
    
    # Validate source directory exists
    if [ ! -d "$dotfiles_configs" ]; then
        log_warning "⚠️ Source directory does not exist: $dotfiles_configs"
        log_warning "Skipping config folder symlinking"
        return 0
    fi
    
    # Create ~/.config if it doesn't exist
    if [ ! -d "$target_config" ]; then
        if ! mkdir -p "$target_config" 2>/dev/null; then
            log_error "❌ Failed to create directory: $target_config"
            return 1
        fi
        log_success "✓ Created directory: $target_config"
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
            log_warning "⚠️ Skipping non-directory: $basename_item"
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
                        log_success "✓ Already linked: $basename_item"
                        linked=$((linked + 1))
                        continue
                    fi
                fi
            fi
            
            if [ -L "$target_path" ] || [ -e "$target_path" ]; then
                log_info "Backing up existing: $basename_item"
                if backup_target "$target_path"; then
                    if rm -rf "$target_path" 2>/dev/null; then
                        log_success "✓ Backed up: $basename_item"
                    else
                        log_error "❌ Failed to remove existing item: $target_path"
                        errors=$((errors + 1))
                        continue
                    fi
                else
                    log_error "❌ Failed to backup: $basename_item"
                    errors=$((errors + 1))
                    continue
                fi
            fi
        fi
        
        # Create the symlink
        if safe_exec ln -sf "$item" "$target_path"; then
            log_success "✓ Linked: $basename_item -> $target_config/$basename_item"
            linked=$((linked + 1))
        else
            log_error "❌ Failed to create symlink: $basename_item"
            errors=$((errors + 1))
        fi
    done
    shopt -u nullglob dotglob
    
    log_info ""
    log_info "Config Symlinking Summary:"
    log_info "  Folders linked: $linked"
    if [ $skipped -gt 0 ]; then
        log_info "  Items skipped: $skipped"
    fi
    if [ $errors -gt 0 ]; then
        log_error "  Errors encountered: $errors"
    fi
    
    if [ $linked -eq 0 ] && [ $errors -eq 0 ]; then
        log_warning "⚠️ No config folders found to link in $dotfiles_configs"
    fi
    
    if [ $errors -gt 0 ]; then
        log_warning "⚠️ $errors error(s) occurred during config folder symlinking"
        return 1
    fi
    
    return 0
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

source_bashrc() {
    log_info "Configuration complete..."
    
    if [ -f "$HOME/.bashrc" ]; then
        log_success "✓ .bashrc is ready"
        log_info ""
        log_info "To activate changes:"
        log_info "  Option 1: Restart shell: exec bash"
        log_info "  Option 2: Reload config: reload"
    else
        log_warning "⚠️ .bashrc not found"
    fi
    
    # Record successful installation
    update_installation_state
}

# =============================================================================
# REVERT FUNCTIONALITY
# =============================================================================

revert_changes() {
    log_info "========================================="
    log_info "Reverting Dotfiles Installation"
    log_info "========================================="

    if [ ! -d "$OLD_FILES" ]; then
        log_error "❌ No backup directory found at: $OLD_FILES"
        log_info "Nothing to revert."
        return 1
    fi

    local reverted=0 failed=0 removed=0

    log_info "Removing symlinks created by the installer..."
    for src in "${DOT_ARRAY[@]}" "$HOME/.tmux" "$HOME/.vim" "$HOME/.tmux.conf" "$HOME/.vimrc"; do
        if [ -L "$src" ]; then
            if rm -f "$src" 2>/dev/null; then
                log_success "✓ Removed symlink: $src"
                removed=$((removed + 1))
            else
                log_error "❌ Failed to remove: $src"
                failed=$((failed + 1))
            fi
        fi
    done

    if restore_backup_manifest; then
        log_success "✓ Restored files from latest manifest"
    else
        log_warning "⚠️ No manifest found, using legacy backup restore as fallback"
    fi

    shopt -s nullglob
    for f in "$OLD_FILES"/*.bak-* "$OLD_FILES"/*.moved-*; do
        [ -f "$f" ] || continue
        local basename_file
        basename_file=$(basename "$f" | sed 's/\.\(bak\|moved\)-.*$//')

        if cp -pf "$f" "$HOME/$basename_file" 2>/dev/null; then
            log_success "✓ Restored: $basename_file"
            reverted=$((reverted + 1))
        else
            log_error "❌ Failed to restore: $basename_file"
            failed=$((failed + 1))
        fi
    done
    shopt -u nullglob

    log_info "========================================="
    log_info "Revert Summary:"
    log_info "  Files restored: $reverted"
    log_info "  Symlinks removed: $removed"
    if [ $failed -gt 0 ]; then
        log_error "  Failed operations: $failed"
    fi
    log_info "========================================="

    if [ $reverted -eq 0 ] && [ $removed -eq 0 ]; then
        log_warning "⚠️ No changes were reverted. Check $OLD_FILES/ manually."
    fi

    log_info ""
    log_info "Manual cleanup steps (if needed):"
    log_info "  1. Review backups: ls -la $OLD_FILES/"
    log_info "  2. Remove dotfiles repo: rm -rf ~/.dotfiles"
    log_info "  3. Restart your shell: exec bash"
    log_info ""
    log_info "See README.md for more information."
}

# =============================================================================
# HELP DOCUMENTATION
# =============================================================================

show_version() {
    echo -e "${GREEN}${BOLD}run_me_first.sh${NC} version ${BLUE}v${VERSION}${NC} (${VERSION_DATE})"
    echo ""
    echo "Dotfiles installer and configuration manager"
    echo "https://bitbucket.org/b0red/dotfiles"
}

show_info() {
    echo -e "${BOLD}run_me_first.sh${NC} v${VERSION} — Dotfiles installer for first-run setup"
    echo ""
    echo -e "  Repo    : ${BLUE}https://bitbucket.org/b0red/dotfiles${NC}"
    echo -e "  Date    : ${VERSION_DATE}"
    echo -e "  Usage   : ./run_me_first.sh [-h|-?] [--dry-run] [-v] [-d] [-r]"
    echo ""
    echo "  Run with -h/--help for full option reference."
}

show_help() {
    echo -e "${BOLD}Usage:${NC} ./run_me_first.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -h, --help        Show this help message"
    echo "  -?, --info        Show condensed script info and exit"
    echo "  -v, --version     Show version information"
    echo "  -r, --revert      Restore backups and remove symlinks"
    echo "  --check           Check installation status without making changes"
    echo "  --select-apps     Choose specific applications from .install_apps.inc"
    echo "  --skip-apps       Skip application installation entirely"
    echo "  -d, --debug       Enable debug mode"
    echo "  --dry-run         Show what would be done without making changes"
    echo "  --trace           Enable trace mode (set -x)"
    echo "  --test-notify     Test the notification system and exit"
    echo "  --notify-only     Run but only emit notifications (no installs)"
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
    echo "  DEBUG=1         Enable debug output (same as -d)"
    echo "  DRY_RUN=1       Dry-run mode (same as --dry-run)"
    echo "  TRACE_DEBUG=1   Enable bash trace mode (same as --trace)"
    echo "  SLEEP=N         Seconds to sleep between operations (default: 2)"
    echo ""
    echo -e "${BOLD}Log files:${NC}"
    echo "  ~/.dotfiles/logs/install-YYYY-MM-DD_HH-MM-SS.log"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./run_me_first.sh                   # Normal installation"
    echo "  ./run_me_first.sh --check           # Check status without changes"
    echo "  ./run_me_first.sh --dry-run         # Preview without changes"
    echo "  ./run_me_first.sh --select-apps     # Choose specific packages to install"
    echo "  ./run_me_first.sh --skip-apps       # Skip package installation"
    echo "  ./run_me_first.sh --version         # Show version"
    echo "  ./run_me_first.sh --revert          # Undo changes (restore backups)"
    echo "  ./run_me_first.sh -d                # Debug mode"
    echo "  TRACE_DEBUG=1 ./run_me_first.sh     # Trace mode"
    echo ""
    echo -e "${BOLD}For detailed documentation, see:${NC} README.md"
}

# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

trap cleanup_on_exit EXIT
trap 'exit $EXIT_ABORT' INT TERM

if [ "${TRACE_DEBUG:-0}" -eq 1 ]; then 
    set -x
    trap 'read -p "DEBUG: Press Enter..."' DEBUG
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run as root!${NC}"
    exit $EXIT_PERM
fi

# =============================================================================
# COMMAND LINE ARGUMENT PARSING
# =============================================================================

case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -\?|--info)
        show_info
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
    --check)
        CHECK_MODE=1
        main
        exit 0
        ;;
    --select-apps)
        INTERACTIVE_APP_SELECTION=1
        main
        exit 0
        ;;
    --skip-apps)
        SKIP_APP_INSTALL=1
        main
        exit 0
        ;;
    -d|--debug)
        DEBUG=1
        main
        exit 0
        ;;
    --dry-run)
        DRY_RUN=1
        log_warning "🔍 DRY RUN — no changes will be made"
        main
        exit 0
        ;;
    --trace)
        TRACE_DEBUG=1
        main
        exit 0
        ;;
    --test-notify)
        echo -e "${YELLOW}⚠️  Notification system not yet configured.${NC}"
        echo "   Add notify integration and re-run --test-notify."
        exit 0
        ;;
    --notify-only)
        echo -e "${YELLOW}⚠️  Notification system not yet configured.${NC}"
        echo "   Add notify integration before using --notify-only."
        exit $EXIT_ERROR
        ;;
    "")
        main
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo ""
        show_help
        exit $EXIT_ERROR
        ;;
esac

# End of run_me_first.sh