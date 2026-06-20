#!/usr/bin/env bash
# =================================================================================================
# docker.bash - Docker & Docker Compose Shortcuts
# =================================================================================================
# Purpose: Docker aliases and helper functions for container management
# Dependencies: docker, docker-compose/docker compose, lazydocker (optional)
# 
# 🔒 INTERACTIVE ONLY - This file contains:
#    - Docker command shortcuts (dps, dcp, dex, etc.)
#    - Docker Compose workflow helpers
#    - Container inspection and management functions
#    - Integration with lazydocker/lazyjournal if installed
# 
# ⚠️ WHY GUARDED?
#    1. Aliases are for human convenience in interactive terminals
#    2. Docker aliases designed for manual container management
#    3. Scripts should use full docker commands for clarity
#    4. These shortcuts assume interactive terminal context
# 
# 🐳 DOCKER CHECK:
#    This file only loads if Docker is actually installed
#    Prevents cluttering the shell with unused aliases
# =================================================================================================

# =============================================================================
# DOCKER INSTALLATION CHECK
# =============================================================================
# Skip loading entirely if Docker is not installed
# This prevents unnecessary aliases and functions when Docker isn't available
if ! command -v docker >/dev/null 2>&1; then
    return 0
fi

# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
# Check if shell is interactive ($- contains 'i')
# If NOT interactive → return immediately
# If interactive → continue loading Docker shortcuts
[[ $- == *i* ]] || return 0

# =============================================================================
# We're in an INTERACTIVE shell with Docker installed - load shortcuts
# =============================================================================

#--------------------------------------
# Helper Functions
#--------------------------------------
command_check() { 
    command -v "$1" >/dev/null 2>&1
}

#--------------------------------------
# Docker Compose Aliases
#--------------------------------------
alias dcp="docker compose -f ~/docker/compose/compose.yml"
alias dci="cd ~/docker/compose && docker compose images"
alias dcub="docker compose -f ~/docker/compose/compose.yml up -d --build"

# Docker Compose v2 commands
alias dcs="docker compose stop"
alias dcd="docker compose down"
alias dcr="docker compose restart"
alias dcls="docker compose logs"
alias dcl="docker logs -f"
alias dclsf='docker container ls --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}"'

#--------------------------------------
# Docker Container Aliases
#--------------------------------------
alias dex="docker exec -it"
alias dps="docker ps"
alias dsa="docker ps -q | xargs -r docker stop"
alias dsp="docker system prune -f"
alias dkprune="docker system prune -af"
alias dcpull="docker compose -f ~/docker/compose/compose.yml pull --parallel"
alias dclogs='docker compose -f ~/docker/compose/compose.yml logs -tf --tail=50'
alias dtail='docker logs -tf --tail=50'
alias dkps="docker ps --format '{{.ID}} - {{.Names}} - {{.Status}} - {{.Image}}'"

#--------------------------------------
# Docker Functions
#--------------------------------------

function drun() {
    ### Check if container is running
    if [ -z "$1" ]; then
        echo "Usage: drun <container-name-or-id>"
        return 1
    fi
    docker inspect -f '{{.State.Status}}' "$1"
}

function did() {
    ### Get container name from ID
    if [ -z "$1" ]; then
        echo "Usage: did <container-id>"
        return 1
    fi
    docker inspect --format='{{.Name}}' "$1" | sed 's/^\///'
}

function dkclean() {
    ### Remove exited containers
    local exited
    exited=$(command docker ps -a -q -f status=exited)
    if [[ -n "$exited" ]]; then
        local -a ids
        mapfile -t ids <<< "$exited"
        command docker rm "${ids[@]}"
        echo "Removed exited containers"
    else
        echo "No exited containers to remove"
    fi
}

function dcrm() {
    ### Recreate a container
    if [ -z "$1" ]; then
        echo "Usage: dcrm <container-name>"
        return 1
    fi
    docker stop "$1"
    docker rm "$1"
    echo "Container removed. Use 'docker compose up -d $1' to recreate"
}

function docker() {
    ### Custom docker wrapper for formatted ps output
    if [[ "$1 $2" = "ps -p" ]]; then
        command docker ps --all --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" \
        | (echo -e "CONTAINER_ID\tNAMES\tIMAGE\tPORTS\tSTATUS"; cat) \
        | awk '{printf "\033[1;32m%s\t\033[01;38;5;95;38;5;196m%s\t\033[00m\033[1;34m%s\t\033[01;90m%s %s %s %s %s %s %s\033[00m\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;}' \
        | column -s$'\t' -t \
        | sort -k2
    else
        command docker "$@"
    fi
}

function dkln() {
    ### Follow logs for named container
    if [ -z "$1" ]; then
        echo "Usage: dkln <container-name>"
        return 1
    fi
    local container
    container=$(docker ps -f name="$1" -q)
    if [[ -z "$container" ]]; then
        echo "No container found with name: $1"
        return 1
    fi
    docker logs -f "$container"
}

function dkstats() {
    ### Show docker stats, optionally filtered
    if [[ $# -eq 0 ]]; then
        docker stats --no-stream
    else
        docker stats --no-stream | grep "$1"
    fi
}

function dktop() {
    ### Show docker container stats in table format
    docker stats --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

function dke() {
    ### Execute shell in container
    if [ -z "$1" ]; then
        echo "Usage: dke <container-name-or-id>"
        return 1
    fi
    docker exec -it "$1" /bin/sh
}

function dkexe() {
    ### Execute command in container
    if [ $# -lt 2 ]; then
        echo "Usage: dkexe <container> <command>"
        return 1
    fi
    docker exec -it "$1" "$2"
}

function dclean() {
    ### Clean up dangling images and volumes
    local images volumes
    images=$(command docker images -q -f dangling=true)
    volumes=$(command docker volume ls -q -f dangling=true)

    if [[ -n "$images" ]]; then
        local -a img_ids
        mapfile -t img_ids <<< "$images"
        command docker rmi "${img_ids[@]}"
        echo "Removed dangling images"
    else
        echo "No dangling images to remove"
    fi

    if [[ -n "$volumes" ]]; then
        local -a vol_ids
        mapfile -t vol_ids <<< "$volumes"
        command docker volume rm "${vol_ids[@]}"
        echo "Removed dangling volumes"
    else
        echo "No dangling volumes to remove"
    fi
}

function dport() {
    ### Find container using specific port
    if [[ -z "$1" ]]; then
        echo "Usage: dport <port>"
        return 1
    fi
    
    local port_to_find="$1"
    local result
    result=$(docker ps --format "{{.ID}}\t{{.Names}}\t{{.Ports}}" | grep "$port_to_find")
    
    if [[ -z "$result" ]]; then
        echo "No running container found on port $port_to_find."
        return 1
    fi
    
    local container_id container_name container_ports
    container_id=$(echo "$result" | awk -F'\t' '{print $1}')
    container_name=$(echo "$result" | awk -F'\t' '{print $2}')
    container_ports=$(echo "$result" | awk -F'\t' '{print $3}')
    
    echo "Found container for port $port_to_find:"
    echo "----------------------------------------"
    echo "Container ID:   $container_id"
    echo "Container Name: $container_name"
    echo "Ports:          $container_ports"
    return 0
}

#--------------------------------------
# Docker Daemon Check Helper
#--------------------------------------
docker_check() {
    ### Verify Docker daemon is running
    if ! docker ps >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Docker daemon is not running. Please start Docker." >&2
        return 1
    fi
    return 0
}

#--------------------------------------
# Lazydocker/Lazyjournal in Tmux
#--------------------------------------
function lzj() {
    ### Launch lazyjournal in tmux window/session
    if ! docker_check; then return 1; fi
    
    if [ -n "$TMUX" ]; then
        # Already in tmux - create new window
        tmux new-window -n lazyjournal "lazyjournal"
        return
    fi
    
    if tmux ls >/dev/null 2>&1; then
        # Tmux running but not attached - create temp session
        tmux new-session -d -s lazyjournal-temp "lazyjournal"
        tmux new-window -t lazyjournal-temp -n lazyjournal "lazyjournal"
        tmux attach-session -t lazyjournal-temp
        return
    fi
    
    # No tmux - run directly
    lazyjournal
}

function lzd() {
    ### Launch lazydocker in tmux window/session
    if ! docker_check; then return 1; fi
    
    if [ -n "$TMUX" ]; then
        # Already in tmux - create new window
        tmux new-window -n lazydocker "lazydocker"
        return
    fi
    
    if tmux ls >/dev/null 2>&1; then
        # Tmux running but not attached - create temp session
        tmux new-session -d -s lazydocker-temp "lazydocker"
        tmux new-window -t lazydocker-temp -n lazydocker "lazydocker"
        tmux attach-session -t lazydocker-temp
        return
    fi
    
    # No tmux - run directly
    lazydocker
}

# End of docker.bash (Interactive Only, Docker Required)