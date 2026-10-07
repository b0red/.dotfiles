#!/bin/sh
#
# Name: docker.sh
# Author: Patrick
# Version: 1.1.0
# Created: 2026-10-08
# Last Modified: 2026-10-08
# Description: tmux-menus custom item "Docker": container picker (fzf: logs / shell /
#              stats / inspect / restart), all containers, lazydocker. Works against the
#              local Docker if this machine has one, otherwise over ssh to the host in the
#              tmux option @docker_menu_host (e.g. from WSL to dellubuntu).
# Usage: Not run directly. tmux_installer.sh copies this file into
#        tmux-menus/custom_items/ (symlinks there are ignored by the plugin).
# Dependencies: tmux-menus (jaclu), POSIX sh; tmux/docker_actions.sh (does all the work)
#
# Changes in 1.1.0: one menu entry per container replaced by an fzf picker (71 running
# containers don't fit in a menu), and remote Docker over ssh. No container data is put
# into tmux command strings any more; the picker passes names as argv.

# Helper that performs everything (repo: tmux/docker_actions.sh, via ~/.tmux)
docker_helper="$HOME/.tmux/docker_actions.sh"

static_content() {
    # shellcheck disable=SC2154 # nav_prev/nav_home/f_custom_items_index: set by tmux-menus
    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S \
        0.0 C c "Containers... (pick, then logs/shell/stats/inspect/restart)" \
        "display-popup -w 95% -h 80% -T Docker -E '$docker_helper pick'" \
        0.0 C a "All containers (docker ps -a)" \
        "display-popup -w 95% -h 80% -T 'docker ps -a' -E '$docker_helper ps'" \
        0.0 C l "lazydocker" \
        "display-popup -w 95% -h 90% -T lazydocker -E '$docker_helper lazydocker'" \
        0.0 S

    menu_generate_part 1 "$@"
}

# Rebuilt on every open: which Docker host the entries above will use. No ssh here, so
# opening the menu stays instant.
dynamic_content() {
    if command -v docker >/dev/null 2>&1; then
        set -- 0.0 T "-#[nodim]Docker host: this machine"
    else
        host="$(tmux show-options -gqv @docker_menu_host 2>/dev/null | tr -cd 'A-Za-z0-9._@-')"
        if [ -n "$host" ]; then
            set -- 0.0 T "-#[nodim]Docker host: $host (via ssh)"
        else
            set -- 0.0 T "-#[nodim]No Docker here; set @docker_menu_host in .tmux.conf"
        fi
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
