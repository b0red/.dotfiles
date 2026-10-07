#!/bin/sh
#
# Name: docker.sh
# Author: Patrick
# Version: 1.0.0
# Created: 2026-10-08
# Last Modified: 2026-10-08
# Description: tmux-menus custom item "Docker": lazydocker, all containers, and one entry
#              per running container (rebuilt every time the menu opens) leading to
#              logs / shell / stats / inspect / restart. Meant for the Docker host
#              (dellubuntu); on a host without Docker it just says so.
# Usage: Not run directly. tmux_installer.sh copies this file into
#        tmux-menus/custom_items/ (symlinks there are ignored by the plugin).
# Dependencies: tmux-menus (jaclu), POSIX sh, docker CLI; tmux/docker_actions.sh;
#               optional: lazydocker
#
# All actions go through docker_actions.sh, which re-validates the container name and
# calls docker with argv. Names are also filtered here (Docker's charset, no leading
# "-") before they are put into a tmux command string, so no container data can break
# the quoting.

# Helper that performs the actions (repo: tmux/docker_actions.sh, via ~/.tmux)
docker_helper="$HOME/.tmux/docker_actions.sh"

static_content() {
    # shellcheck disable=SC2154 # nav_prev/nav_home/f_custom_items_index: set by tmux-menus
    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S

    if command -v lazydocker >/dev/null 2>&1; then
        set -- "$@" \
            0.0 C L "lazydocker" "display-popup -w 95% -h 90% -T lazydocker -E lazydocker"
    fi
    set -- "$@" \
        0.0 C A "All containers (docker ps -a)" \
        "display-popup -w 95% -h 80% -T 'docker ps -a' -E '$docker_helper ps'" \
        0.0 S \
        0.0 T "-#[nodim]Running containers"

    menu_generate_part 1 "$@"
}

dynamic_content() {
    keys="123456789abcdefghijkmnoqrstuvwxyz"
    shown=0
    skipped=0
    tab="$(printf '\t')"

    set --
    if ! command -v docker >/dev/null 2>&1; then
        set -- 0.0 T "-#[nodim]Docker is not installed on this host"
        menu_generate_part 2 "$@"
        return
    fi
    if ! list="$(docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null)"; then
        set -- 0.0 T "-#[nodim]Cannot reach the Docker daemon (docker group?)"
        menu_generate_part 2 "$@"
        return
    fi
    if [ -z "$list" ]; then
        set -- 0.0 T "-#[nodim]No running containers"
        menu_generate_part 2 "$@"
        return
    fi

    # here-doc, not a pipe: the loop must run in this shell so `set --` sticks
    while IFS="$tab" read -r name status; do
        case "$name" in
            "" | -* | *[!a-zA-Z0-9_.-]*)
                skipped=$((skipped + 1))
                continue
                ;;
        esac
        if [ "$shown" -ge "${#keys}" ]; then
            skipped=$((skipped + 1))
            continue
        fi
        shown=$((shown + 1))
        key="$(printf '%s' "$keys" | cut -c"$shown")"
        # status is display text only: keep it to harmless characters, short
        status="$(printf '%s' "$status" | tr -cd 'A-Za-z0-9 ().:-' | cut -c1-24)"

        set -- "$@" \
            0.0 C "$key" "$name  ($status)" \
            "display-menu -T '#[align=centre] $name ' -x C -y C \
'Logs (follow)' l 'new-window -n log-$name \"$docker_helper logs $name\"' \
'Shell' s 'new-window -n sh-$name \"$docker_helper shell $name\"' \
'Stats' t 'display-popup -w 90% -h 40% -T stats-$name -E \"$docker_helper stats $name\"' \
'Inspect' i 'new-window -n insp-$name \"$docker_helper inspect $name\"' \
'' \
'Restart...' r 'display-popup -w 60% -h 30% -T restart-$name -E \"$docker_helper restart $name\"'"
    done <<EOF
$list
EOF

    if [ "$skipped" -gt 0 ]; then
        set -- "$@" 0.0 T "-#[nodim]$skipped more not shown (use All containers)"
    fi
    menu_generate_part 2 "$@"
}

#===============================================================
#
#   Main
#
#===============================================================

# shellcheck disable=SC2034 # read by tmux-menus (menu_handling.sh, update_custom_inventory.sh)
menu_name="Docker"

# Shortcut for this menu in the Custom items index
# shellcheck disable=SC2034 # read by tmux-menus' update_custom_inventory.sh
menu_key="D"

# Full path to tmux-menus plugin (this file runs from <plugin>/custom_items/)
D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

# shellcheck source=/dev/null
. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
