#!/usr/bin/env bash
# =============================================================================
# Name:         tmux_installer.sh
# Author:       b0red
# Version:      2.0.0
# Created:      2026-01-29
# Last Modified:2026-06-21
# Description:  Install and configure tmux with the Coffee plugin manager.
#               Creates ~/.tmux.conf symlink pointing into the dotfiles repo,
#               installs Coffee, and verifies the configuration.
#               Runs standalone — can be used without the full dotfiles installer.
# Usage:        ./tmux_installer.sh [OPTIONS]
# Dependencies: git, tmux (will offer to install missing ones)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# Globals
# =============================================================================
readonly SCRIPT_NAME="tmux_installer.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly VERSION="2.0.0"

# Paths derived from SCRIPT_DIR so they're correct regardless of where the
# dotfiles repo is cloned.
readonly TMUX_CONF_TARGET="${SCRIPT_DIR}/.tmux.conf"
readonly TMUX_CONF_LINK="${HOME}/.tmux.conf"
readonly COFFEE_REPO="https://github.com/PraaneshSelvaraj/coffee.tmux"
readonly COFFEE_DIR="${HOME}/.local/share/coffee"

DRY_RUN=0
DEBUG=0
INTERACTIVE=0

# =============================================================================
# Colors (inline — no ColorCodes.inc dependency)
# =============================================================================
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' NC=''
fi

# =============================================================================
# Logging
# =============================================================================
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error()   { echo -e "${RED}❌${NC} $*" >&2; }
log_warn()    { echo -e "${YELLOW}⚠️ ${NC} $*"; }
log_info()    { echo -e "  $*"; }
log_section() { echo -e "\n${BOLD}${CYAN}==========================================${NC}"; echo -e "${BOLD}${CYAN} $*${NC}"; echo -e "${BOLD}${CYAN}==========================================${NC}"; }
log_dry()     { echo -e "${YELLOW}[DRY-RUN]${NC} Would: $*"; }

# =============================================================================
# safe_exec: run a mutating command, or log+skip it in dry-run mode
# =============================================================================
safe_exec() {
    if [ "${DRY_RUN}" -eq 1 ]; then
        log_dry "$*"
        return 0
    fi
    "$@"
}

# =============================================================================
# Helper: yes/no prompt
# =============================================================================
ask_yes_or_no() {
    local prompt="$1"
    local reply
    read -rp "$prompt ([y]es or [N]o): " reply
    case "$(echo "$reply" | tr '[:upper:]' '[:lower:]')" in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

# =============================================================================
# Helper: install a package using available package manager
# Uses p_install if available (from sourced dotfiles), otherwise detects PM.
# =============================================================================
pkg_install() {
    local pkg="$1"
    if declare -f p_install >/dev/null 2>&1; then
        p_install "$pkg"
        return
    fi
    if   command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y "$pkg"
    elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y "$pkg"
    elif command -v yum     >/dev/null 2>&1; then sudo yum install -y "$pkg"
    elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm "$pkg"
    elif command -v zypper  >/dev/null 2>&1; then sudo zypper install -y "$pkg"
    elif command -v apk     >/dev/null 2>&1; then sudo apk add "$pkg"
    elif command -v brew    >/dev/null 2>&1; then brew install "$pkg"
    else
        log_error "No supported package manager found — install '$pkg' manually"
        return 1
    fi
}

# =============================================================================
# check_dependencies: verify required tools are present, offer to install
# =============================================================================
check_dependencies() {
    local installed=0
    local missing=0

    log_section "Checking Dependencies"

    for prog in git tmux; do
        if command -v "$prog" >/dev/null 2>&1; then
            log_success "$prog is installed"
            installed=$((installed + 1))
        else
            log_error "'$prog' is not installed"
            if [[ "$(ask_yes_or_no "Install '$prog' now?")" == "yes" ]]; then
                if [ "${DRY_RUN}" -eq 1 ]; then
                    log_dry "pkg_install $prog"
                    installed=$((installed + 1))
                elif pkg_install "$prog"; then
                    log_success "$prog installed"
                    installed=$((installed + 1))
                else
                    log_error "Failed to install $prog"
                    missing=$((missing + 1))
                fi
            else
                log_warn "Skipped: $prog"
                missing=$((missing + 1))
            fi
        fi
    done

    echo ""
    log_info "Summary: $installed ready, $missing missing"

    if [ "$missing" -gt 0 ]; then
        log_error "Required software is missing — cannot continue"
        return 1
    fi
    return 0
}

# =============================================================================
# create_symlink: link ~/.tmux.conf → repo .tmux.conf
# =============================================================================
create_symlink() {
    log_section "Creating ~/.tmux.conf Symlink"

    if [ ! -f "${TMUX_CONF_TARGET}" ]; then
        log_error "Source not found: ${TMUX_CONF_TARGET}"
        log_info "Expected the .tmux.conf to be in the same directory as this script."
        return 1
    fi

    if [ -L "${TMUX_CONF_LINK}" ]; then
        safe_exec rm -f "${TMUX_CONF_LINK}"
        log_info "Removed existing symlink"
    elif [ -e "${TMUX_CONF_LINK}" ]; then
        local backup
        backup="${TMUX_CONF_LINK}.backup-$(date +%Y%m%d-%H%M%S)"
        safe_exec mv "${TMUX_CONF_LINK}" "${backup}"
        log_success "Backed up existing file → ${backup}"
    fi

    if safe_exec ln -s "${TMUX_CONF_TARGET}" "${TMUX_CONF_LINK}"; then
        log_success "Created: ${TMUX_CONF_LINK} → ${TMUX_CONF_TARGET}"
    else
        log_error "Failed to create symlink"
        return 1
    fi
}

# =============================================================================
# install_coffee: clone and set up the Coffee plugin manager
# =============================================================================
install_coffee() {
    log_section "Coffee Plugin Manager"

    if [ -d "${COFFEE_DIR}/.git" ]; then
        log_success "Coffee already installed at: ${COFFEE_DIR}"
        if [[ "$(ask_yes_or_no "Update Coffee to latest?")" == "yes" ]]; then
            if safe_exec git -C "${COFFEE_DIR}" pull 2>&1; then
                log_success "Coffee updated"
            else
                log_error "Failed to update Coffee"
                return 1
            fi
        else
            log_warn "Skipping Coffee update"
        fi
        return 0
    fi

    if [ -e "${COFFEE_DIR}" ]; then
        log_warn "${COFFEE_DIR} exists but is not a git repo"
        if [[ "$(ask_yes_or_no "Remove and reinstall Coffee?")" != "yes" ]]; then
            log_warn "Skipping Coffee installation"
            return 1
        fi
        safe_exec rm -rf -- "${COFFEE_DIR}"
        log_info "Removed existing directory"
    fi

    safe_exec mkdir -p "$(dirname "${COFFEE_DIR}")"

    log_info "Cloning Coffee from: ${COFFEE_REPO}"
    if safe_exec env GIT_TERMINAL_PROMPT=0 git clone --depth=1 "${COFFEE_REPO}" "${COFFEE_DIR}" 2>&1; then
        log_success "Coffee cloned → ${COFFEE_DIR}"
    else
        log_error "Failed to clone Coffee from ${COFFEE_REPO}"
        return 1
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        log_info "Setting up Python virtual environment..."
        if python3 -m venv "${COFFEE_DIR}/.venv" 2>&1; then
            log_success "Virtual environment created"
            if "${COFFEE_DIR}/.venv/bin/python" -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1 \
            && "${COFFEE_DIR}/.venv/bin/python" -m pip install -r "${COFFEE_DIR}/requirements.txt" >/dev/null 2>&1; then
                log_success "Coffee Python dependencies installed"
            else
                log_warn "Failed to install Coffee Python dependencies"
                log_info "Check: ${COFFEE_DIR}/requirements.txt"
            fi
        else
            log_warn "Failed to create virtual environment"
        fi
    else
        log_warn "Python3 not found — install Python 3.10+ and re-run to complete Coffee setup"
    fi

    log_info ""
    log_info "Add Coffee to PATH (append to ~/.bashrc):"
    log_info "  export PATH=\"${COFFEE_DIR}/bin:\$PATH\""
}

# =============================================================================
# verify_installation: validate symlink and config
# =============================================================================
verify_installation() {
    log_section "Verifying Installation"

    if [ "${DRY_RUN}" -eq 1 ]; then
        log_dry "verify symlink and tmux config"
        return 0
    fi

    # Check symlink
    if [ -L "${TMUX_CONF_LINK}" ] && [ -e "${TMUX_CONF_LINK}" ]; then
        local actual_target
        actual_target="$(readlink -f "${TMUX_CONF_LINK}" 2>/dev/null || readlink "${TMUX_CONF_LINK}")"
        local expected_target
        expected_target="$(readlink -f "${TMUX_CONF_TARGET}" 2>/dev/null || echo "${TMUX_CONF_TARGET}")"

        if [ "${actual_target}" = "${expected_target}" ]; then
            log_success "Symlink verified → correct target"
        else
            log_warn "Symlink points to unexpected location"
            log_info "  Expected: ${expected_target}"
            log_info "  Actual:   ${actual_target}"
        fi
    else
        log_error "Symlink missing or broken: ${TMUX_CONF_LINK}"
    fi

    # Check tmux parses the config
    if command -v tmux >/dev/null 2>&1; then
        if tmux -f "${TMUX_CONF_LINK}" list-keys >/dev/null 2>&1; then
            log_success "Tmux config parses without errors"
        else
            log_warn "Tmux config may have errors — run: tmux -f ~/.tmux.conf list-keys"
        fi
    fi

    # Check Coffee
    if [ -d "${COFFEE_DIR}/.git" ]; then
        log_success "Coffee installed at: ${COFFEE_DIR}"
    else
        log_warn "Coffee not found or incomplete — run: ${SCRIPT_NAME} to retry"
    fi
}

# =============================================================================
# show_brief_help / show_help
# =============================================================================
show_brief_help() {
    echo "Usage: ${SCRIPT_NAME} [OPTIONS]"
    echo "       ${SCRIPT_NAME} --help for full help"
}

show_help() {
    cat << EOF

${BOLD}${SCRIPT_NAME} v${VERSION}${NC}
Install tmux config symlink and Coffee plugin manager.

${BOLD}USAGE${NC}
  ${SCRIPT_NAME} [OPTIONS]

${BOLD}OPTIONS${NC}
  -h, --help      Show this help
  -?, --info      Show this help
  -v, --version   Show version
  -d, --debug     Enable set -x tracing
  --dry-run       Preview all actions without making changes (exits 4)

${BOLD}WHAT IT DOES${NC}
  1. Checks for git and tmux (offers to install if missing)
  2. Creates: ~/.tmux.conf → ${TMUX_CONF_TARGET}
  3. Installs Coffee plugin manager to ${COFFEE_DIR}
  4. Verifies symlink and tmux config

${BOLD}NOTES${NC}
  The dotfiles installer (run_me_first.sh) already handles step 2.
  Run this script to (re)install Coffee or reset the symlink manually.

${BOLD}EXIT CODES${NC}
  0   Success
  1   General error
  2   Invalid argument
  3   Missing dependencies
  4   Dry-run completed
  5   Notification test

EOF
}

# =============================================================================
# parse_args
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help|-\?|--info)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "${SCRIPT_NAME} v${VERSION}"
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                set -x
                ;;
            --dry-run)
                DRY_RUN=1
                log_warn "DRY RUN — no changes will be made"
                ;;
            --test-notify|--notify-only)
                echo "${SCRIPT_NAME}: notification backend not configured"
                exit 5
                ;;
            *)
                log_error "Unknown option: $1"
                show_brief_help
                exit 2
                ;;
        esac
        shift
    done
}

# =============================================================================
# validate_environment
# =============================================================================
validate_environment() {
    if [ ! -f "${TMUX_CONF_TARGET}" ]; then
        log_error "Config not found: ${TMUX_CONF_TARGET}"
        log_error "Run this script from inside the dotfiles repo (${SCRIPT_DIR})."
        exit 1
    fi
}

# =============================================================================
# cleanup
# =============================================================================
cleanup() {
    : # nothing to clean up
}
trap cleanup EXIT INT TERM

# =============================================================================
# main
# =============================================================================
main() {
    parse_args "$@"
    validate_environment

    echo ""
    echo -e "${BOLD}${SCRIPT_NAME} v${VERSION}${NC}"
    echo -e "Tmux config: ${CYAN}${TMUX_CONF_TARGET}${NC}"
    echo ""

    check_dependencies || exit 3
    create_symlink      || exit 1
    install_coffee      || log_warn "Coffee installation failed — continuing"
    verify_installation

    log_section "Installation Complete"
    echo ""
    log_success "${HOME}/.tmux.conf symlink created"
    if [ -d "${COFFEE_DIR}/.git" ]; then
        log_success "Coffee ready at ${COFFEE_DIR}"
    fi
    echo ""
    log_info "Next steps:"
    log_info "  1. Start tmux: tmux"
    log_info "  2. Install plugins: coffee install"
    log_info "  3. Open Coffee TUI in tmux: Ctrl-a then C"
    echo ""

    if [ "${DRY_RUN}" -eq 1 ]; then
        log_warn "Dry-run complete — no changes were made"
        exit 4
    fi
}

# =============================================================================
# Execution guard
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
