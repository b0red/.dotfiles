#!/usr/bin/env bash
set -euo pipefail

# Name: start_tmux.sh
# Author: Patrick
# Version: 1.0.0
# Created: 2026-05-06
# Last Modified: 2026-10-07
# Description: Attach to (or create) the main tmux session with the standard pane layout:
#              left 50% in ~/bin, top-right in ~/docker/compose, bottom-right running mc,
#              plus a Taskwarrior pane when `task` is installed. Refuses to run inside
#              tmux (see tmux_guard.inc). Normally launched by .bashrc auto-start via the
#              ~/.start_tmux.sh symlink.
# Usage: ./start_tmux.sh [OPTIONS]
# Dependencies: bash, tmux (>= 3.1), tmux_guard.inc; optional: mc, task

IFS=$'\n\t'

# Resolve through the ~/.start_tmux.sh symlink so SCRIPT_DIR is the repo's tmux/ dir
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

# Always /tmp (socket: /tmp/tmux-$UID/default). Also set in exports.bash; pinned here so
# the script is self-contained and every launcher reaches the same server.
export TMUX_TMPDIR="/tmp"

readonly TMUX_CONF="${HOME}/.tmux.conf"
readonly GUARD_INC="${SCRIPT_DIR}/tmux_guard.inc"

# Session name is the lowercased kernel name ("linux"). tmux-resurrect saves and restores
# by this name, so changing it orphans the saved layout.
SESSION_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
readonly SESSION_NAME

# notification_functions.inc is only loaded for --test-notify/--notify-only: this script
# runs on every terminal open and should not pay for (or depend on) it otherwise. Checked
# next to the script first, then in ~/bin where the shared library lives. Missing library
# exits 3 at that point, so no NOTIFICATIONS_AVAILABLE flag is needed.

DRY_RUN=0
DEBUG=0
INTERACTIVE=0
HAS_MC=0
HAS_TASK=0
LEFT_DIR=""
TOP_RIGHT_DIR=""

if [[ -t 0 ]]; then
    INTERACTIVE=1
fi

# Every log function sets `local IFS=' '`: "$*" joins with the first char of IFS, and the
# script-wide IFS=$'\n\t' would split a multi-part message across lines.
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

# Dry-run lines always print (unlike log_info, which is silent when non-interactive):
# a dry-run that hides its actions is useless.
function log_dryrun() {
    local IFS=' '
    echo -e "${CYAN}[DRY-RUN] Would execute: $*${NC}"
}

function show_version() {
    echo -e "${CYAN}${SCRIPT_NAME} version ${VERSION}${NC}"
}

function safe_exec() {
    if [[ $DRY_RUN -eq 1 ]]; then
        # printf %q, not "$*": with IFS=$'\n\t', "$*" would join arguments with newlines
        log_dryrun "$(printf '%q ' "$@")"
        return 0
    fi
    log_debug "Executing: $(printf '%q ' "$@")"
    "$@"
}

# Like safe_exec for tmux commands that create a pane, but prints the new pane's id
# (%N) on stdout so callers can target it. In dry-run it prints a placeholder instead,
# and the dry-run message goes to stderr so command substitution doesn't swallow it.
function tmux_new_pane() {
    local placeholder="$1"
    shift
    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "$(printf '%q ' tmux "$@" -P -F '#{pane_id}')" >&2
        echo "${placeholder}"
        return 0
    fi
    log_debug "Executing: $(printf '%q ' tmux "$@" -P -F '#{pane_id}')"
    tmux "$@" -P -F '#{pane_id}'
}

# Re-source the config into an already running server so it picks up edits. A broken
# config must not cost the user their shell, so failure warns (loudly, with tmux's own
# message) and the caller carries on.
function reload_config() {
    local output=""

    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "$(printf '%q ' tmux source-file "${TMUX_CONF}")"
        return 0
    fi
    if ! output="$(tmux source-file "${TMUX_CONF}" 2>&1)"; then
        log_warning "tmux config reload failed (${TMUX_CONF}): ${output}"
    fi
}

function show_brief_help() {
    echo "${SCRIPT_NAME} - attach to or create the main tmux session with the standard layout"
}

function show_help() {
    if [[ $INTERACTIVE -eq 1 ]]; then
        echo -e "${CYAN}NAME${NC}"
        echo "    ${SCRIPT_NAME} - attach to or create the main tmux session"
        echo ""
        echo -e "${CYAN}SYNOPSIS${NC}"
        echo "    ${SCRIPT_NAME} [OPTIONS]"
        echo ""
        echo -e "${CYAN}DESCRIPTION${NC}"
        echo "    If session '${SESSION_NAME}' exists, reloads ${TMUX_CONF} and attaches."
        echo "    Otherwise creates it with this layout and attaches:"
        echo "        left 50%     ~/bin (or ~)"
        echo "        top-right    ~/docker/compose (or ~)"
        echo "        bottom-right mc (if installed), focused"
        echo "        bottom-most  task list (only if Taskwarrior is installed)"
        echo ""
        echo "    Never starts tmux inside tmux: it exits without doing anything when run"
        echo "    from a tmux pane, even if \$TMUX was stripped (sudo -i, su -, sudo mc, ssh"
        echo "    to this host), and never runs as root. Socket: /tmp/tmux-\$UID/default."
        echo ""
        echo -e "${CYAN}OPTIONS${NC}"
        echo -e "    ${YELLOW}-h, --help${NC}        Show this help"
        echo -e "    ${YELLOW}-?, --info${NC}        Show brief description"
        echo -e "    ${YELLOW}-v, --version${NC}     Show version"
        echo -e "    ${YELLOW}-d, --debug${NC}       Enable debug output (set -x)"
        echo -e "    ${YELLOW}--dry-run${NC}         Show the tmux commands without running them"
        echo -e "    ${YELLOW}--test-notify${NC}     Send test notifications and exit"
        echo -e "    ${YELLOW}--notify-only${NC}     Send a success notification only"
        echo ""
        echo -e "${CYAN}EXIT CODES${NC}"
        echo "    0  attached/detached normally, or skipped because already inside tmux"
        echo "    1  error (no terminal, nesting check failed, tmux command failed)"
        echo "    2  invalid argument"
        echo "    3  missing dependency (tmux, ${TMUX_CONF}, tmux_guard.inc, notifications)"
        echo "    4  dry-run completed"
        echo "    5  test notifications sent"
        echo ""
        echo -e "${CYAN}FILES${NC}"
        echo "    ${TMUX_CONF}"
        echo "    ${GUARD_INC}"
        echo "    ~/.start_tmux.sh (symlink to this script, used by .bashrc auto-start)"
    else
        show_brief_help
        echo "Usage: ${SCRIPT_NAME} [-h|-?|-v|-d|--dry-run|--test-notify|--notify-only]"
    fi
}

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

function validate_environment() {
    if ! command -v tmux >/dev/null 2>&1; then
        log_error "tmux is not installed (sudo apt install tmux)"
        exit 3
    fi
    if [[ ! -f "${TMUX_CONF}" ]]; then
        log_error "${TMUX_CONF} not found -- run run_me_first.sh to link it"
        exit 3
    fi
    if [[ $DRY_RUN -eq 0 && ( ! -t 0 || ! -t 1 ) ]]; then
        log_error "attaching to tmux needs a terminal on stdin/stdout"
        exit 1
    fi
}

# Exits 0 (nothing to do) when we're inside tmux, 1 when the guard can't decide.
function check_not_nested() {
    local reason=""
    local rc=0

    if [[ ! -f "${GUARD_INC}" ]]; then
        log_error "${GUARD_INC} not found -- refusing to start without the nesting guard"
        exit 3
    fi
    # shellcheck source-path=SCRIPTDIR source=tmux_guard.inc
    source "${GUARD_INC}"

    if reason="$(tmux_guard_should_skip)"; then
        rc=0
    else
        rc=$?
    fi
    case "${rc}" in
        0)
            log_warning "not starting tmux: ${reason}"
            exit 0
            ;;
        1)
            log_debug "nesting guard: clear to start"
            ;;
        *)
            log_error "nesting guard failed: ${reason}"
            exit 1
            ;;
    esac
}

function resolve_settings() {
    LEFT_DIR="${HOME}"
    if [[ -d "${HOME}/bin" ]]; then
        LEFT_DIR="${HOME}/bin"
    fi
    TOP_RIGHT_DIR="${HOME}"
    if [[ -d "${HOME}/docker/compose" ]]; then
        TOP_RIGHT_DIR="${HOME}/docker/compose"
    fi
    if command -v mc >/dev/null 2>&1; then
        HAS_MC=1
    fi
    if command -v task >/dev/null 2>&1; then
        HAS_TASK=1
    fi
    log_debug "session=${SESSION_NAME} left=${LEFT_DIR} right=${TOP_RIGHT_DIR}" \
        "mc=${HAS_MC} task=${HAS_TASK}"
}

function create_session() {
    local left_pane=""
    local top_right_pane=""
    local bottom_right_pane=""
    local task_pane=""

    # A running server already parsed the config at its own start; refresh it so edits
    # apply. -f below only takes effect when new-session starts a fresh server.
    if tmux list-sessions >/dev/null 2>&1; then
        reload_config
    fi

    log_step "Creating tmux session '${SESSION_NAME}'"
    # Panes are addressed by id (%N), not window.pane index, so the layout doesn't
    # depend on base-index/pane-base-index from the config having loaded.
    left_pane="$(tmux_new_pane "%left" -f "${TMUX_CONF}" new-session -d \
        -s "${SESSION_NAME}" -c "${LEFT_DIR}")"
    top_right_pane="$(tmux_new_pane "%top-right" split-window -h -t "${left_pane}" \
        -c "${TOP_RIGHT_DIR}")"
    bottom_right_pane="$(tmux_new_pane "%bottom-right" split-window -v -l 40% \
        -t "${top_right_pane}" -c "${TOP_RIGHT_DIR}")"
    if [[ $HAS_TASK -eq 1 ]]; then
        task_pane="$(tmux_new_pane "%task" split-window -v -l 20% \
            -t "${bottom_right_pane}" -c "${TOP_RIGHT_DIR}")"
    fi

    # Pane shells need a moment to initialise; without it send-keys fires before bash
    # is ready and the keys are swallowed.
    safe_exec sleep 1

    safe_exec tmux send-keys -t "${left_pane}" "clear" C-m
    safe_exec tmux send-keys -t "${top_right_pane}" "clear" C-m
    if [[ $HAS_MC -eq 1 ]]; then
        safe_exec tmux send-keys -t "${bottom_right_pane}" "clear && mc" C-m
    else
        safe_exec tmux send-keys -t "${bottom_right_pane}" "clear" C-m
    fi
    if [[ -n "${task_pane}" ]]; then
        # `task list`, not the `tasks` alias: pane shells may not have aliases loaded yet
        safe_exec tmux send-keys -t "${task_pane}" "clear && task list" C-m
    fi

    safe_exec tmux select-pane -t "${bottom_right_pane}"
}

function cleanup() {
    # Nothing to release: no temp files or background jobs. Kept for the canonical
    # EXIT trap so future resources have one place to be cleaned up.
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
    check_not_nested
    validate_environment
    resolve_settings

    if tmux has-session -t "=${SESSION_NAME}" 2>/dev/null; then
        log_step "Attaching to existing session '${SESSION_NAME}'"
        reload_config
    else
        create_session
    fi

    safe_exec tmux attach-session -t "=${SESSION_NAME}"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "Dry-run complete -- no tmux commands were run"
        exit 4
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
