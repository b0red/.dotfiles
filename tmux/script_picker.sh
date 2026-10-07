#!/usr/bin/env bash
set -euo pipefail

# Name: script_picker.sh
# Author: Patrick
# Version: 1.0.0
# Created: 2026-10-08
# Last Modified: 2026-10-08
# Description: fzf picker for the scripts in ~/bin, opened from the tmux Tools menu.
#              Lists every *.sh with its "# Description:" header (read from the file,
#              never by running it) and a source preview. Enter = dry-run in a new tmux
#              window (or view the source if the script has no --dry-run), Ctrl-X = real
#              run after asking for arguments and confirmation, Ctrl-V = view source.
# Usage: ./script_picker.sh [OPTIONS]
# Dependencies: bash, fzf, tmux (must run inside tmux), less

IFS=$'\n\t'

# Resolve through any symlink so SCRIPT_DIR is the repo's tmux/ dir
SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_PATH
SCRIPT_NAME="$(basename "${SCRIPT_PATH}")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
readonly SCRIPT_DIR
readonly VERSION="1.0.0"

if [[ -f "${SCRIPT_DIR}/ColorCodes.inc" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/ColorCodes.inc"
else
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly MAGENTA='\033[0;35m'
    readonly NC='\033[0m'
fi

# Directory to pick from; override with SCRIPT_PICKER_DIR=/path
PICK_DIR="${SCRIPT_PICKER_DIR:-${HOME}/bin}"
readonly PICK_DIR

DRY_RUN=0
DEBUG=0
INTERACTIVE=0
ACTION="pick"
TARGET=""

if [[ -t 0 ]]; then
    INTERACTIVE=1
fi

# Every log function sets `local IFS=' '`: "$*" joins with the first char of IFS.
function log_error() {
    local IFS=' '
    echo -e "${RED}❌ ERROR: $*${NC}" >&2
}

function log_success() {
    local IFS=' '
    echo -e "${GREEN}✔ $*${NC}"
}

function log_warning() {
    local IFS=' '
    echo -e "${YELLOW}⚠ WARNING: $*${NC}" >&2
}

function log_info() {
    local IFS=' '
    if [[ $DEBUG -eq 1 || $INTERACTIVE -eq 1 ]]; then
        echo -e "${CYAN}ℹ $*${NC}"
    fi
}

function log_step() {
    local IFS=' '
    echo -e "${BLUE}▶ $*${NC}"
}

function log_debug() {
    local IFS=' '
    if [[ $DEBUG -eq 1 ]]; then
        echo -e "${MAGENTA}[DEBUG] $*${NC}" >&2
    fi
}

function log_dryrun() {
    local IFS=' '
    echo -e "${CYAN}[DRY-RUN] Would execute: $*${NC}"
}

function show_version() {
    echo -e "${CYAN}${SCRIPT_NAME} version ${VERSION}${NC}"
}

function safe_exec() {
    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "$(printf '%q ' "$@")"
        return 0
    fi
    log_debug "Executing: $(printf '%q ' "$@")"
    "$@"
}

function show_brief_help() {
    echo "${SCRIPT_NAME} - fzf picker that runs ~/bin scripts in a new tmux window"
}

function show_help() {
    if [[ $INTERACTIVE -eq 1 ]]; then
        echo -e "${CYAN}NAME${NC}"
        echo "    ${SCRIPT_NAME} - pick and run a script from ${PICK_DIR}"
        echo ""
        echo -e "${CYAN}SYNOPSIS${NC}"
        echo "    ${SCRIPT_NAME} [OPTIONS]"
        echo ""
        echo -e "${CYAN}DESCRIPTION${NC}"
        echo "    Lists ${PICK_DIR}/*.sh with the first '# Description:' header line of"
        echo "    each (read from the file -- nothing is executed to build the list)."
        echo "    Normally opened from the tmux Tools menu (prefix + \\ -> Custom items ->"
        echo "    Tools -> s). Keys in the picker:"
        echo "        Enter   dry-run in a new tmux window (script --dry-run); scripts"
        echo "                without --dry-run open their source instead"
        echo "        Ctrl-X  real run in a new window: asks for arguments, then y/N"
        echo "        Ctrl-V  view the source in a new window"
        echo "        Esc     close"
        echo ""
        echo -e "${CYAN}OPTIONS${NC}"
        echo -e "    ${YELLOW}-h, --help${NC}        Show this help"
        echo -e "    ${YELLOW}-?, --info${NC}        Show brief description"
        echo -e "    ${YELLOW}-v, --version${NC}     Show version"
        echo -e "    ${YELLOW}-d, --debug${NC}       Enable debug output (set -x)"
        echo -e "    ${YELLOW}--dry-run${NC}         Pick, then print the tmux command instead of"
        echo "                      opening the window (exits 4)"
        echo -e "    ${YELLOW}--list${NC}            Print the script list and exit (no fzf/tmux needed)"
        echo -e "    ${YELLOW}--test-notify${NC}     Send test notifications and exit"
        echo -e "    ${YELLOW}--notify-only${NC}     Send a success notification only"
        echo ""
        echo "    Internal (used for the new tmux window): --exec-dry PATH,"
        echo "    --exec-live PATH, --view PATH"
        echo ""
        echo -e "${CYAN}ENVIRONMENT${NC}"
        echo "    SCRIPT_PICKER_DIR   directory to list (default: ~/bin)"
        echo ""
        echo -e "${CYAN}EXIT CODES${NC}"
        echo "    0 ok/cancelled, 1 error, 2 bad argument, 3 missing dependency,"
        echo "    4 dry-run complete, 5 test notifications sent"
    else
        show_brief_help
        echo "Usage: ${SCRIPT_NAME} [-h|-?|-v|-d|--dry-run|--list|--test-notify|--notify-only]"
    fi
}

# notification_functions.inc only loaded for the notify flags; missing -> exit 3
function load_notifications() {
    local lib=""

    for lib in "${SCRIPT_DIR}/notification_functions.inc" "${HOME}/bin/notification_functions.inc"; do
        if [[ -f "${lib}" ]]; then
            # shellcheck source=/dev/null
            source "${lib}"
            return 0
        fi
    done
    log_error "notification_functions.inc not found next to the script or in ~/bin"
    exit 3
}

# The path arrives via argv (from fzf or the tmux window command): only accept an
# executable regular file directly inside PICK_DIR.
function validate_target() {
    local path="$1"
    local real=""
    local dir_real=""

    if [[ -z "${path}" ]]; then
        log_error "no script path given"
        exit 2
    fi
    real="$(readlink -f -- "${path}")" || { log_error "cannot resolve: ${path}"; exit 2; }
    dir_real="$(readlink -f -- "${PICK_DIR}")" || { log_error "cannot resolve: ${PICK_DIR}"; exit 3; }
    if [[ "$(dirname -- "${real}")" != "${dir_real}" || ! -f "${real}" || ! -x "${real}" ]]; then
        log_error "not an executable script in ${PICK_DIR}: ${path}"
        exit 2
    fi
    TARGET="${real}"
}

function supports_dry_run() {
    grep -q -- '--dry-run' "$1"
}

# One tab-separated line per script: name, [dry-run] tag, description, full path
function build_list() {
    local f=""
    local desc=""
    local tag=""

    for f in "${PICK_DIR}"/*.sh; do
        [[ -f "${f}" && -x "${f}" ]] || continue
        desc="$(awk 'NR > 40 { exit }
            /^#[[:space:]]*Description[[:space:]]*:/ {
                sub(/^#[[:space:]]*Description[[:space:]]*:[[:space:]]*/, ""); print; exit }' "${f}")"
        tag="          "
        if supports_dry_run "${f}"; then
            tag="[dry-run] "
        fi
        printf '%s\t%s\t%s\t%s\n' "$(basename "${f}")" "${tag}" "${desc:-(no description)}" "${f}"
    done
}

function pause_window() {
    local rc="$1"

    echo ""
    if [[ "${rc}" -eq 0 ]]; then
        echo -e "${GREEN}✔ exit code 0${NC}"
    elif [[ "${rc}" -eq 4 ]]; then
        echo -e "${CYAN}ℹ exit code 4 (dry-run complete)${NC}"
    else
        echo -e "${RED}❌ exit code ${rc}${NC}"
    fi
    read -r -n 1 -s -p "Press any key to close this window..." || true
    echo ""
}

function exec_dry() {
    local rc=0

    validate_target "$1"
    log_step "Dry-run: ${TARGET} --dry-run"
    echo ""
    "${TARGET}" --dry-run || rc=$?
    pause_window "${rc}"
}

function exec_live() {
    local rc=0
    local argline=""
    local answer=""
    local args=()

    validate_target "$1"
    echo -e "${YELLOW}About to run for real:${NC} ${TARGET}"
    echo "(Arguments are split on spaces; quoting is not supported here.)"
    read -r -e -p "Arguments (blank for none): " argline || true
    if [[ -n "${argline}" ]]; then
        IFS=' ' read -r -a args <<< "${argline}"
    fi
    read -r -p "Run '$(basename "${TARGET}") ${argline}' now? [y/N] " answer || answer=""
    if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        pause_window 0
        return 0
    fi
    echo ""
    "${TARGET}" "${args[@]}" || rc=$?
    pause_window "${rc}"
}

function view_source() {
    validate_target "$1"
    less -R -- "${TARGET}"
}

function validate_environment() {
    if [[ ! -d "${PICK_DIR}" ]]; then
        log_error "script directory not found: ${PICK_DIR} (set SCRIPT_PICKER_DIR)"
        exit 3
    fi
    if [[ "${ACTION}" == "pick" ]]; then
        if ! command -v fzf >/dev/null 2>&1; then
            log_error "fzf is required (sudo apt install fzf)"
            exit 3
        fi
        if [[ -z "${TMUX:-}" ]]; then
            log_error "must run inside tmux (it opens the script in a new tmux window)"
            exit 1
        fi
    fi
}

function pick() {
    local selection=""
    local key=""
    local line=""
    local path=""
    local name=""
    local mode=""

    # --expect prints the pressed key on line 1, the chosen line on line 2
    selection="$(build_list | fzf --delimiter=$'\t' --with-nth=1,2,3 --tabstop=4 \
        --expect=ctrl-x,ctrl-v --header='Enter: dry-run   Ctrl-X: run for real   Ctrl-V: view source' \
        --preview='sed -n "1,80p" {4}' --preview-window='right,55%,wrap')" || return 0
    key="$(sed -n '1p' <<< "${selection}")"
    line="$(sed -n '2p' <<< "${selection}")"
    [[ -n "${line}" ]] || return 0
    path="$(cut -f4 <<< "${line}")"
    validate_target "${path}"
    name="$(basename "${TARGET}" .sh)"

    case "${key}" in
        ctrl-x) mode="--exec-live" ;;
        ctrl-v) mode="--view" ;;
        *)
            if supports_dry_run "${TARGET}"; then
                mode="--exec-dry"
            else
                log_warning "$(basename "${TARGET}") has no --dry-run -- opening its source instead"
                mode="--view"
            fi
            ;;
    esac

    # argv form (several args after --): tmux runs it without a shell, so no quoting.
    # -e passes PICK_DIR on: the new window gets the tmux server's environment, not ours,
    # and validate_target in the child must check against the same directory.
    safe_exec tmux new-window -n "${name}" -c "${PICK_DIR}" -e "SCRIPT_PICKER_DIR=${PICK_DIR}" \
        -- "${SCRIPT_PATH}" "${mode}" "${TARGET}"
    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "Dry-run complete -- no window opened"
        exit 4
    fi
}

function cleanup() {
    # Nothing to release: no temp files or background jobs.
    :
}

# Never put cleanup on INT/TERM: bash would run it and carry on with the next command.
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

function parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -\?|--info)
                show_brief_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                set -x
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --list)
                ACTION="list"
                shift
                ;;
            --exec-dry|--exec-live|--view)
                ACTION="${1#--}"
                TARGET="${2:-}"
                shift
                [[ $# -gt 0 ]] && shift
                ;;
            --test-notify)
                load_notifications
                notify_success "Test success notification from ${SCRIPT_NAME}"
                notify_warning "Test warning notification from ${SCRIPT_NAME}"
                notify_error "Test error notification from ${SCRIPT_NAME}"
                log_success "Test notifications sent (check your configured channels)."
                exit 5
                ;;
            --notify-only)
                load_notifications
                notify_success "${SCRIPT_NAME} completed"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1 (see --help)"
                exit 2
                ;;
        esac
    done
}

function main() {
    parse_args "$@"
    validate_environment

    case "${ACTION}" in
        list)      build_list | cut -f1-3 ;;
        exec-dry)  exec_dry "${TARGET}" ;;
        exec-live) exec_live "${TARGET}" ;;
        view)      view_source "${TARGET}" ;;
        *)         pick ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
