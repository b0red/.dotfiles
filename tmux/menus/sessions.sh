#!/bin/sh
#
# Name: sessions.sh
# Author: Patrick
# Version: 1.0.0
# Created: 2026-10-08
# Last Modified: 2026-10-08
# Description: tmux-menus custom item "Sessions": lists all tmux sessions with window and
#              attached-client counts (rebuilt every time the menu opens); per session:
#              switch to it, or detach every client attached to it. Plus: detach this
#              terminal, pick a client to detach (choose-client), detach all other
#              clients, and the session/window tree.
# Usage: Not run directly. tmux_installer.sh copies this file into
#        tmux-menus/custom_items/ (symlinks there are ignored by the plugin).
# Dependencies: tmux-menus (jaclu), POSIX sh, tmux 3.0+ ({ } command blocks)
#
# Session names only go into tmux command strings when they are made of [A-Za-z0-9_-]
# (no quotes, spaces, '#', '$', ...), so a name can't break the quoting or be expanded
# as a format/variable. Other sessions are listed but not actionable from here (use
# "Session tree" for those).

static_content() {
    # shellcheck disable=SC2154 # nav_prev/nav_home/f_custom_items_index: set by tmux-menus
    set -- \
        0.0 M Left "Back to Custom items  $nav_prev" "$f_custom_items_index" \
        0.0 M Home "Back to Main menu     $nav_home" main.sh \
        0.0 S \
        0.0 C d "Detach this terminal" "detach-client" \
        0.0 C c "Clients... (d = detach highlighted)" "choose-client -Z" \
        0.0 C o "Detach all other clients" \
        "confirm-before -p 'Detach every other client (all sessions)? (y/n)' { detach-client -a }" \
        0.0 C t "Session tree (switch / preview)" "choose-tree -Zs" \
        0.0 S \
        0.0 T "-#[nodim]Sessions (windows, attached clients)"

    menu_generate_part 1 "$@"
}

dynamic_content() {
    keys="123456789abefghijkmnpqrsuvwxyz"
    tab="$(printf '\t')"
    shown=0
    other=0

    current="$(tmux display-message -p '#{session_name}' 2>/dev/null)"
    list="$(tmux list-sessions -F "#{session_name}${tab}#{session_windows}${tab}#{session_attached}" 2>/dev/null)"

    set --
    # here-doc, not a pipe: the loop must run in this shell so `set --` sticks
    while IFS="$tab" read -r name windows attached; do
        [ -n "$name" ] || continue
        case "$name" in
            *[!A-Za-z0-9_-]*)
                other=$((other + 1))
                continue
                ;;
        esac
        if [ "$shown" -ge "${#keys}" ]; then
            other=$((other + 1))
            continue
        fi
        shown=$((shown + 1))
        key="$(printf '%s' "$keys" | cut -c"$shown")"
        label="$name  ($windows win, $attached attached)"
        [ "$name" = "$current" ] && label="$label  <- current"

        set -- "$@" \
            0.0 C "$key" "$label" \
            "display-menu -T '#[align=centre] $name ' -x C -y C \
'Switch to it' s 'switch-client -t =$name' \
'Detach its clients' d \"confirm-before -p 'Detach all clients from $name? (y/n)' { detach-client -s =$name }\""
    done <<EOF
$list
EOF

    if [ "$other" -gt 0 ]; then
        set -- "$@" 0.0 T "-#[nodim]$other more (unusual names or too many) - use Session tree"
    fi
    if [ "$shown" -eq 0 ] && [ "$other" -eq 0 ]; then
        set -- "$@" 0.0 T "-#[nodim]No sessions found"
    fi
    menu_generate_part 2 "$@"
}

#===============================================================
#
#   Main
#
#===============================================================

# shellcheck disable=SC2034 # read by tmux-menus (menu_handling.sh, update_custom_inventory.sh)
menu_name="Sessions"

# Shortcut for this menu in the Custom items index
# shellcheck disable=SC2034 # read by tmux-menus' update_custom_inventory.sh
menu_key="S"

# Full path to tmux-menus plugin (this file runs from <plugin>/custom_items/)
D_TM_BASE_PATH=$(cd -- "$(dirname -- "$0")/.." && pwd)

# shellcheck source=/dev/null
. "$D_TM_BASE_PATH"/scripts/menu_handling.sh
