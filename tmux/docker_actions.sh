#!/usr/bin/env bash
set -euo pipefail

# Name: docker_actions.sh
# Author: Patrick
# Version: 1.1.0
# Created: 2026-10-08
# Last Modified: 2026-10-08
# Description: Backend for the tmux Docker menu (tmux/menus/docker.sh): an fzf container
#              picker plus single actions (logs, shell, stats, inspect, restart with y/N,
#              docker ps -a, lazydocker). Uses local Docker when this machine has it,
#              otherwise runs docker over ssh on the host named by the tmux option
#              @docker_menu_host (or $DOCKER_MENU_HOST). Validates container and host
#              names before use; errors stay on screen until a key is pressed.
# Usage: ./docker_actions.sh [OPTIONS] ACTION [CONTAINER]
# Dependencies: bash, docker CLI locally or ssh (key auth) to a host with docker, fzf
#               (pick), less; optional: lazydocker
#
# Changes in 1.1.0:
#   - Remote Docker over ssh (@docker_menu_host) when there is no local docker -- the
#     menu runs in the local tmux, which on WSL has no Docker.
#   - New `pick` action (fzf over running containers): a menu can't hold 71 containers.
#   - Fatal errors pause before exiting, so a popup doesn't vanish unread.

IFS=$'\n\t'

SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_PATH
SCRIPT_NAME="$(basename "${SCRIPT_PATH}")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
readonly SCRIPT_DIR
readonly VERSION="1.1.0"

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
# never be mistaken for options.
readonly NAME_RE='^[a-zA-Z0-9][a-zA-Z0-9_.-]*$'
# ssh alias, host or user@host -- no leading "-" (would be read as an ssh option)
readonly HOST_RE='^[A-Za-z0-9][A-Za-z0-9._@-]*$'
readonly SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)

DRY_RUN=0
DEBUG=0
INTERACTIVE=0
ACTION=""
CONTAINER=""
DOCKER_REMOTE=""   # empty = local docker, else the ssh host

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

function pause_window() {
    local rc="$1"

    echo ""
    if [[ "${rc}" -eq 0 ]]; then
        echo -e "${GREEN}✔ done${NC}"
    else
        echo -e "${RED}❌ exit code ${rc}${NC}"
    fi
    if [[ -t 0 && -t 1 ]]; then
        read -r -n 1 -s -p "Press any key to close..." || true
        echo ""
    fi
}

# Fatal error: in a popup/window, keep the message on screen before exiting
function die() {
    local rc="$1"
    shift
    log_error "$@"
    if [[ -t 0 && -t 1 ]]; then
        read -r -n 1 -s -p "Press any key to close..." || true
        echo ""
    fi
    exit "${rc}"
}

function show_brief_help() {
    echo "${SCRIPT_NAME} - backend for the tmux Docker menu (local or over ssh)"
}

function show_help() {
    if [[ $INTERACTIVE -eq 1 ]]; then
        echo -e "${CYAN}NAME${NC}"
        echo "    ${SCRIPT_NAME} - backend for the tmux Docker menu"
        echo ""
        echo -e "${CYAN}SYNOPSIS${NC}"
        echo "    ${SCRIPT_NAME} [OPTIONS] ACTION [CONTAINER]"
        echo ""
        echo -e "${CYAN}ACTIONS${NC}"
        echo "    pick                fzf over running containers, then:"
        echo "                          Enter logs, Ctrl-S shell, Ctrl-T stats,"
        echo "                          Ctrl-O inspect, Ctrl-R restart (opens a new tmux window)"
        echo "    logs CONTAINER      follow the last 200 log lines"
        echo "    shell CONTAINER     interactive shell in the container (bash, else sh)"
        echo "    stats CONTAINER     live resource usage"
        echo "    inspect CONTAINER   docker inspect, paged"
        echo "    restart CONTAINER   docker restart after a y/N confirmation"
        echo "    ps                  all containers (docker ps -a), paged"
        echo "    lazydocker          lazydocker on the Docker host"
        echo "    target              print which Docker host would be used"
        echo ""
        echo -e "${CYAN}DOCKER HOST${NC}"
        echo "    Local docker if this machine has it. Otherwise ssh to the host in"
        echo "    \$DOCKER_MENU_HOST or the tmux option @docker_menu_host (set in .tmux.conf),"
        echo "    using key auth (BatchMode, no password prompts)."
        echo ""
        echo -e "${CYAN}OPTIONS${NC}"
        echo -e "    ${YELLOW}-h, --help${NC}        Show this help"
        echo -e "    ${YELLOW}-?, --info${NC}        Show brief description"
        echo -e "    ${YELLOW}-v, --version${NC}     Show version"
        echo -e "    ${YELLOW}-d, --debug${NC}       Enable debug output (set -x)"
        echo -e "    ${YELLOW}--dry-run${NC}         Print the command instead of running it (exits 4)"
        echo -e "    ${YELLOW}--test-notify${NC}     Send test notifications and exit"
        echo -e "    ${YELLOW}--notify-only${NC}     Send a success notification only"
        echo ""
        echo -e "${CYAN}EXIT CODES${NC}"
        echo "    0 ok/cancelled, 1 command failed, 2 bad argument/container,"
        echo "    3 no usable Docker (local or remote), 4 dry-run complete, 5 test notifications"
    else
        show_brief_help
        echo "Usage: ${SCRIPT_NAME} [-h|-?|-v|-d|--dry-run]" \
            "{pick|logs|shell|stats|inspect|restart|ps|lazydocker|target} [CONTAINER]"
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

# Local docker wins; otherwise the configured ssh host.
function resolve_target() {
    local host=""

    if command -v docker >/dev/null 2>&1; then
        DOCKER_REMOTE=""
        return 0
    fi
    host="${DOCKER_MENU_HOST:-}"
    if [[ -z "${host}" && -n "${TMUX:-}" ]]; then
        host="$(tmux show-options -gqv @docker_menu_host 2>/dev/null || true)"
    fi
    if [[ -z "${host}" ]]; then
        die 3 "Docker is not installed on this machine and no Docker host is configured" \
            "(set -g @docker_menu_host '<ssh-host>' in .tmux.conf)"
    fi
    if [[ ! "${host}" =~ ${HOST_RE} ]]; then
        die 2 "invalid Docker host name: ${host}"
    fi
    DOCKER_REMOTE="${host}"
}

function target_label() {
    if [[ -z "${DOCKER_REMOTE}" ]]; then
        echo "this machine"
    else
        echo "${DOCKER_REMOTE} (ssh)"
    fi
}

# Read-only docker query; always runs (also in dry-run). Remote: args are shell-quoted
# with %q because ssh joins them into one string for the remote shell. -n: never read
# our stdin -- otherwise ssh swallows input meant for a later prompt (e.g. restart y/N).
function docker_q() {
    if [[ -z "${DOCKER_REMOTE}" ]]; then
        docker "$@"
    else
        ssh -n "${SSH_OPTS[@]}" -- "${DOCKER_REMOTE}" "docker $(printf '%q ' "$@")"
    fi
}

# Docker action (via safe_exec, so --dry-run prints it). -t = needs a terminal.
function docker_x() {
    local tty=0

    if [[ "${1:-}" == "-t" ]]; then
        tty=1
        shift
    fi
    if [[ -z "${DOCKER_REMOTE}" ]]; then
        safe_exec docker "$@"
    elif [[ ${tty} -eq 1 ]]; then
        safe_exec ssh "${SSH_OPTS[@]}" -t -- "${DOCKER_REMOTE}" "docker $(printf '%q ' "$@")"
    else
        safe_exec ssh -n "${SSH_OPTS[@]}" -- "${DOCKER_REMOTE}" "docker $(printf '%q ' "$@")"
    fi
}

function validate_environment() {
    resolve_target
    if ! docker_q info >/dev/null 2>&1; then
        if [[ -z "${DOCKER_REMOTE}" ]]; then
            die 3 "cannot reach the Docker daemon (is it running? are you in the docker group?)"
        fi
        die 3 "cannot run docker on ${DOCKER_REMOTE} over ssh (key auth? docker group there?)"
    fi
}

# Name comes from argv (picker or tmux window command): check the charset and that the
# container exists before handing it to docker.
function validate_container() {
    if [[ -z "${CONTAINER}" ]]; then
        die 2 "action '${ACTION}' needs a container name"
    fi
    if [[ ! "${CONTAINER}" =~ ${NAME_RE} ]]; then
        die 2 "invalid container name: ${CONTAINER}"
    fi
    if ! docker_q inspect --type container "${CONTAINER}" >/dev/null 2>&1; then
        die 2 "no such container on $(target_label): ${CONTAINER}"
    fi
}

function do_restart() {
    local answer=""
    local rc=0

    read -r -p "Restart container '${CONTAINER}' on $(target_label)? [y/N] " answer || answer=""
    if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        pause_window 0
        return 0
    fi
    docker_x restart "${CONTAINER}" || rc=$?
    pause_window "${rc}"
    return "${rc}"
}

function do_lazydocker() {
    local rc=0

    if [[ -z "${DOCKER_REMOTE}" ]]; then
        command -v lazydocker >/dev/null 2>&1 || die 3 "lazydocker is not installed on this machine"
        safe_exec lazydocker || rc=$?
    else
        safe_exec ssh "${SSH_OPTS[@]}" -t -- "${DOCKER_REMOTE}" \
            'command -v lazydocker >/dev/null 2>&1 && exec lazydocker; echo "lazydocker is not installed on this host"; exit 3' \
            || rc=$?
    fi
    if [[ "${rc}" -ne 0 ]]; then
        pause_window "${rc}"
    fi
    return "${rc}"
}

# fzf over running containers; the chosen action opens in a new tmux window (argv form,
# no shell). DOCKER_MENU_HOST is passed on: the new window gets the tmux server's
# environment, not ours.
function do_pick() {
    local list=""
    local selection=""
    local key=""
    local line=""
    local name=""
    local action=""

    command -v fzf >/dev/null 2>&1 || die 3 "fzf is required for the container picker (sudo apt install fzf)"
    [[ -n "${TMUX:-}" ]] || die 1 "pick must run inside tmux (it opens the action in a new window)"

    list="$(docker_q ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}')" \
        || die 3 "could not list containers on $(target_label)"
    if [[ -z "${list}" ]]; then
        echo "No running containers on $(target_label)."
        pause_window 0
        return 0
    fi

    selection="$(fzf --delimiter=$'\t' --with-nth=1,2,3 --tabstop=4 \
        --expect=ctrl-s,ctrl-t,ctrl-o,ctrl-r \
        --header="Docker on $(target_label) — Enter: logs  Ctrl-S: shell  Ctrl-T: stats  Ctrl-O: inspect  Ctrl-R: restart" \
        <<< "${list}")" || return 0
    key="$(sed -n '1p' <<< "${selection}")"
    line="$(sed -n '2p' <<< "${selection}")"
    [[ -n "${line}" ]] || return 0
    name="$(cut -f1 <<< "${line}")"
    if [[ ! "${name}" =~ ${NAME_RE} ]]; then
        die 2 "invalid container name: ${name}"
    fi

    case "${key}" in
        ctrl-s) action="shell" ;;
        ctrl-t) action="stats" ;;
        ctrl-o) action="inspect" ;;
        ctrl-r) action="restart" ;;
        *)      action="logs" ;;
    esac
    safe_exec tmux new-window -n "${action}-${name}" -e "DOCKER_MENU_HOST=${DOCKER_REMOTE}" \
        -- "${SCRIPT_PATH}" "${action}" "${name}"
}

function run_action() {
    local rc=0

    case "${ACTION}" in
        pick)
            do_pick || rc=$?
            ;;
        logs)
            validate_container
            log_step "docker logs -f --tail 200 ${CONTAINER} on $(target_label)   (Ctrl-C to stop)"
            docker_x -t logs -f --tail 200 "${CONTAINER}" || rc=$?
            pause_window "${rc}"
            ;;
        shell)
            validate_container
            # bash if the image has it, else sh; the sh -c string is fixed text
            docker_x -t exec -it "${CONTAINER}" sh -c \
                'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi' \
                || rc=$?
            pause_window "${rc}"
            ;;
        stats)
            validate_container
            docker_x -t stats "${CONTAINER}" || rc=$?
            pause_window "${rc}"
            ;;
        inspect)
            validate_container
            if [[ $DRY_RUN -eq 1 ]]; then
                docker_x inspect "${CONTAINER}"
            else
                docker_q inspect "${CONTAINER}" | less -R || rc=$?
            fi
            ;;
        restart)
            validate_container
            do_restart || rc=$?
            ;;
        ps)
            if [[ $DRY_RUN -eq 1 ]]; then
                docker_x ps -a
            else
                docker_q ps -a | less -RS || rc=$?
            fi
            ;;
        lazydocker)
            do_lazydocker || rc=$?
            ;;
        target)
            target_label
            ;;
        *)
            die 2 "unknown action: ${ACTION:-<none>} (see --help)"
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
                die 2 "Unknown option: $1 (see --help)"
                ;;
            *)
                if [[ -z "${ACTION}" ]]; then
                    ACTION="$1"
                elif [[ -z "${CONTAINER}" ]]; then
                    CONTAINER="$1"
                else
                    die 2 "unexpected argument: $1"
                fi
                shift
                ;;
        esac
    done
}

function main() {
    local rc=0

    parse_args "$@"
    if [[ "${ACTION}" == "target" ]]; then
        resolve_target
        target_label
        exit 0
    fi
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
