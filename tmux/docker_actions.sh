#!/usr/bin/env bash
set -euo pipefail

# Name: docker_actions.sh
# Author: Patrick
# Version: 1.0.0
# Created: 2026-10-08
# Last Modified: 2026-10-08
# Description: Runs one Docker action for the tmux Docker menu (tmux/menus/docker.sh):
#              follow logs, shell, stats, inspect, restart (asks y/N), or list all
#              containers. Validates the container name before use and calls docker with
#              argv (no shell string building), so the menu never quotes container data.
# Usage: ./docker_actions.sh [OPTIONS] ACTION [CONTAINER]
# Dependencies: bash, docker CLI (user in the docker group), less

IFS=$'\n\t'

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

# Docker's own rule for container names. Also guarantees no leading "-", so names can
# never be mistaken for options (no "--" needed before them).
readonly NAME_RE='^[a-zA-Z0-9][a-zA-Z0-9_.-]*$'

DRY_RUN=0
DEBUG=0
INTERACTIVE=0
ACTION=""
CONTAINER=""

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

function show_version() {
    echo -e "${CYAN}${SCRIPT_NAME} version ${VERSION}${NC}"
}

function safe_exec() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${CYAN}[DRY-RUN] Would execute: $(printf '%q ' "$@")${NC}"
        return 0
    fi
    log_debug "Executing: $(printf '%q ' "$@")"
    "$@"
}

function show_brief_help() {
    echo "${SCRIPT_NAME} - one Docker action for the tmux Docker menu"
}

function show_help() {
    if [[ $INTERACTIVE -eq 1 ]]; then
        echo -e "${CYAN}NAME${NC}"
        echo "    ${SCRIPT_NAME} - one Docker action for the tmux Docker menu"
        echo ""
        echo -e "${CYAN}SYNOPSIS${NC}"
        echo "    ${SCRIPT_NAME} [OPTIONS] ACTION [CONTAINER]"
        echo ""
        echo -e "${CYAN}ACTIONS${NC}"
        echo "    logs CONTAINER      follow the last 200 log lines (docker logs -f)"
        echo "    shell CONTAINER     interactive shell in the container (bash, else sh)"
        echo "    stats CONTAINER     live resource usage (docker stats)"
        echo "    inspect CONTAINER   docker inspect, paged"
        echo "    restart CONTAINER   docker restart after a y/N confirmation"
        echo "    ps                  all containers (docker ps -a), paged"
        echo ""
        echo "    Normally run by the tmux Docker menu (prefix + \\ -> Custom items ->"
        echo "    Docker). Windows/popups wait for a key before closing."
        echo ""
        echo -e "${CYAN}OPTIONS${NC}"
        echo -e "    ${YELLOW}-h, --help${NC}        Show this help"
        echo -e "    ${YELLOW}-?, --info${NC}        Show brief description"
        echo -e "    ${YELLOW}-v, --version${NC}     Show version"
        echo -e "    ${YELLOW}-d, --debug${NC}       Enable debug output (set -x)"
        echo -e "    ${YELLOW}--dry-run${NC}         Print the docker command instead of running it (exits 4)"
        echo -e "    ${YELLOW}--test-notify${NC}     Send test notifications and exit"
        echo -e "    ${YELLOW}--notify-only${NC}     Send a success notification only"
        echo ""
        echo -e "${CYAN}EXIT CODES${NC}"
        echo "    0 ok/cancelled, 1 docker command failed, 2 bad argument/container,"
        echo "    3 docker missing or unreachable, 4 dry-run complete, 5 test notifications"
    else
        show_brief_help
        echo "Usage: ${SCRIPT_NAME} [-h|-?|-v|-d|--dry-run] {logs|shell|stats|inspect|restart|ps} [CONTAINER]"
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

function pause_window() {
    local rc="$1"

    echo ""
    if [[ "${rc}" -eq 0 ]]; then
        echo -e "${GREEN}✔ done${NC}"
    else
        echo -e "${RED}❌ exit code ${rc}${NC}"
    fi
    read -r -n 1 -s -p "Press any key to close..." || true
    echo ""
}

function validate_environment() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "docker CLI not found on this host"
        exit 3
    fi
    if ! docker info >/dev/null 2>&1; then
        log_error "cannot reach the Docker daemon (is it running? are you in the docker group?)"
        exit 3
    fi
}

# Name comes from argv (built by the menu from `docker ps`): check the charset and that
# the container exists before handing it to docker.
function validate_container() {
    if [[ -z "${CONTAINER}" ]]; then
        log_error "action '${ACTION}' needs a container name"
        exit 2
    fi
    if [[ ! "${CONTAINER}" =~ ${NAME_RE} ]]; then
        log_error "invalid container name: ${CONTAINER}"
        exit 2
    fi
    if ! docker inspect --type container "${CONTAINER}" >/dev/null 2>&1; then
        log_error "no such container: ${CONTAINER}"
        exit 2
    fi
}

function do_restart() {
    local answer=""
    local rc=0

    read -r -p "Restart container '${CONTAINER}'? [y/N] " answer || answer=""
    if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        pause_window 0
        return 0
    fi
    safe_exec docker restart "${CONTAINER}" || rc=$?
    pause_window "${rc}"
    return "${rc}"
}

function run_action() {
    local rc=0

    case "${ACTION}" in
        logs)
            validate_container
            log_step "docker logs -f --tail 200 ${CONTAINER}   (Ctrl-C to stop)"
            safe_exec docker logs -f --tail 200 "${CONTAINER}" || rc=$?
            pause_window "${rc}"
            ;;
        shell)
            validate_container
            # bash if the image has it, else sh; the container name is a separate argv
            # element, the sh -c string is fixed text
            safe_exec docker exec -it "${CONTAINER}" sh -c \
                'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi' \
                || rc=$?
            pause_window "${rc}"
            ;;
        stats)
            validate_container
            safe_exec docker stats "${CONTAINER}" || rc=$?
            pause_window "${rc}"
            ;;
        inspect)
            validate_container
            if [[ $DRY_RUN -eq 1 ]]; then
                safe_exec docker inspect "${CONTAINER}"
            else
                docker inspect "${CONTAINER}" | less -R || rc=$?
            fi
            ;;
        restart)
            validate_container
            do_restart || rc=$?
            ;;
        ps)
            if [[ $DRY_RUN -eq 1 ]]; then
                safe_exec docker ps -a
            else
                docker ps -a | less -RS || rc=$?
            fi
            ;;
        *)
            log_error "unknown action: ${ACTION:-<none>} (see --help)"
            exit 2
            ;;
    esac
    return "${rc}"
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
            -*)
                log_error "Unknown option: $1 (see --help)"
                exit 2
                ;;
            *)
                if [[ -z "${ACTION}" ]]; then
                    ACTION="$1"
                elif [[ -z "${CONTAINER}" ]]; then
                    CONTAINER="$1"
                else
                    log_error "unexpected argument: $1"
                    exit 2
                fi
                shift
                ;;
        esac
    done
}

function main() {
    local rc=0

    parse_args "$@"
    validate_environment
    run_action || rc=$?
    if [[ $DRY_RUN -eq 1 ]]; then
        exit 4
    fi
    exit "${rc}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
