#!/usr/bin/env bash
# shellcheck shell=bash
#
# Name: tmux_guard.inc
# Author: Patrick
# Version: 1.0.0
# Created: 2026-10-07
# Last Modified: 2026-10-07
# Description: Shared "must we NOT start tmux here?" check, sourced by .bashrc (auto-start)
#              and tmux/start_tmux.sh. Single source of truth so the two can't drift.
# Usage: source ~/.tmux/tmux_guard.inc
#        reason="$(tmux_guard_should_skip)"; rc=$?
# Dependencies: bash, /proc (Linux)
#
# Why this exists: checking $TMUX alone is not enough. sudo -i, su -, `sudo mc` subshells
# and ssh-to-self all strip it, which let a pane launch a second tmux inside itself
# (stacked status lines). This library defines functions only; sourcing it has no side
# effects and changes no shell options.

# Prints a one-line reason on stdout. Return codes:
#   0 = do NOT start tmux (reason printed)
#   1 = safe to start tmux
#   2 = could not determine (reason printed) -- callers must treat this as "do not start"
tmux_guard_should_skip() {
    local pid="$$"
    local comm=""
    local stat=""
    local ssh_client=""
    local ssh_server=""

    if [[ -n "${TMUX:-}" ]]; then
        echo "already inside tmux (\$TMUX is set)"
        return 0
    fi

    if (( EUID == 0 )) || [[ -n "${SUDO_USER:-}" ]]; then
        echo "running as root/sudo -- tmux is never auto-started for root"
        return 0
    fi

    # Walk the ancestry: catches shells whose environment was wiped (sudo -i, su -).
    while [[ "$pid" =~ ^[0-9]+$ ]] && (( pid > 1 )); do
        if ! { comm="$(< "/proc/${pid}/comm")"; } 2>/dev/null; then
            echo "cannot read /proc/${pid}/comm -- unable to rule out nesting"
            return 2
        fi
        if [[ "$comm" == "tmux: server" ]]; then
            echo "a parent process is a tmux server (pid ${pid})"
            return 0
        fi
        if ! { stat="$(< "/proc/${pid}/stat")"; } 2>/dev/null; then
            echo "cannot read /proc/${pid}/stat -- unable to rule out nesting"
            return 2
        fi
        # comm inside stat may contain spaces ("tmux: server"): split after the last ')'
        IFS=' ' read -r _ pid _ <<< "${stat##*) }"
    done

    # ssh to this same host breaks the process chain (sshd is the parent, not tmux).
    # SSH_CONNECTION = "client_ip client_port server_ip server_port"; a session from this
    # host has client == server address, or a loopback client.
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        IFS=' ' read -r ssh_client _ ssh_server _ <<< "$SSH_CONNECTION"
        if [[ "$ssh_client" == "$ssh_server" || "$ssh_client" == 127.* \
            || "$ssh_client" == "::1" || "$ssh_client" == ::ffff:127.* ]]; then
            echo "ssh session from this same host (${ssh_client}) -- likely ssh from a pane"
            return 0
        fi
    fi

    return 1
}
