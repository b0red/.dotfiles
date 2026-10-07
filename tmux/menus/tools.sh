#!/bin/sh
#
# Name: tools.sh
# Author: Patrick
# Version: 1.1.0
# Created: 2026-10-07
# Last Modified: 2026-10-08
# Description: tmux-menus custom item "Tools": launchers for monitors and utilities that
#              used to be one-off prefix keys in .tmux.conf. Shown under
#              Main menu (prefix \) -> Custom items -> Tools.
# Usage: Not run directly. tmux_installer.sh copies this file into
#        tmux-menus/custom_items/ (the plugin ignores symlinks there: it scans with
#        `find -type f`), and tmux-menus indexes it on the next config load.
# Dependencies: tmux-menus (jaclu), POSIX sh; optional: htop, btop, lazyports, urlview
#
# Entry format (tmux-menus): <min tmux version> <type> <key> "<label>" "<command>"
#   C = tmux command (a tmux format: #{...} is expanded against the current pane)
#   T = text line, S = separator, M = submenu
# Menu content is cached by tmux-menus, so the `command -v` checks below run when the
# cache is (re)built, not on every open.

static_content() {
    # Captured to a private temp file (mktemp), not a fixed /tmp path another user
    # could pre-create as a symlink; removed after urlview exits.
    urlview_cmd="new-window -n urlview 'f=\$(mktemp) \
&& tmux capture-pane -p -J -t #{pane_id} >\"\$f\" && urlview \"\$f\"; rm -f \"\$f\"'"

    # nav_prev/nav_home/f_custom_items_index are set by menu_handling.sh before it
    # calls static_content()
    # shellcheck disable=SC2154 # defined by tmux-menus (menu_handling.sh, helpers_full.sh)
    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S \
        0.0 T "-#[nodim]Monitors" \
        0.0 C h "htop        (popup)" "display-popup -w 80% -h 80% -T Htop -E htop" \
        0.0 C H "htop        (window)" "new-window -n htop htop" \
        0.0 C b "btop        (popup)" "display-popup -w 80% -h 80% -T B-Top -E btop" \
        0.0 C B "btop        (window)" "new-window -n btop btop" \
        0.0 C l "lazyports   (popup)" \
        "display-popup -w 60% -h 40% -T lazyports -E lazyports" \
        0.0 C L "lazyports   (window)" "new-window -n lazyports lazyports" \
        0.0 C t "Task monitor" \
        "run-shell '$HOME/.tmux/coffee/plugins/tmux-task-monitor/scripts/launch_monitor.sh'" \
        0.0 C T "Task overview" \
        "run-shell '$HOME/.tmux/coffee/plugins/tmux-task-monitor/scripts/launch_overview.sh'" \
        0.0 S \
        0.0 T "-#[nodim]Utilities" \
        0.0 C s "Run a ~/bin script..." \
        "display-popup -w 90% -h 85% -T 'Scripts (~/bin)' -E '$HOME/.tmux/script_picker.sh'" \
        0.0 C m "Man page..." "command-prompt -p 'Man page:' 'split-window \"exec man %%\"'"

    if command -v urlview >/dev/null 2>&1; then
        set -- "$@" \
            0.0 C u "URLs in this pane (urlview)" "$urlview_cmd"
    else
        set -- "$@" \
            0.0 T "-#[nodim]urlview not installed (sudo apt install urlview)"
    fi

    set -- "$@" \
        0.0 C c "Coffee plugin manager" \
        "display-popup -E '$HOME/.local/share/coffee/.venv/bin/python $HOME/.local/share/coffee/ui.py'" \
        0.0 S \
        0.0 T "-#[nodim]Direct keys: prefix + h b l (popups), t T (task monitor)"

    menu_generate_part 1 "$@"
}

#===============================================================
#
#   Main
#
#===============================================================

# shellcheck disable=SC2034 # read by tmux-menus (menu_handling.sh, update_custom_inventory.sh)
menu_name="Tools"

# Shortcut for this menu in the Custom items index
# shellcheck disable=SC2034 # read by tmux-menus' update_custom_inventory.sh
menu_key="T"

# Full path to tmux-menus plugin (this file runs from <plugin>/custom_items/)
D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

# shellcheck source=/dev/null
. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
