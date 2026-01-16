#!/usr/bin/env bash
# ------------------------------------------------------------------------
# docker.bash - FULL ORIGINAL DOCKER ALIASES/FUNCTIONS (FIXED)
# ------------------------------------------------------------------------
# Original content 100% preserved. Fixes: quoting, returns, consistency (docker compose v2).
# Guarded/idempotent. Comments added for readability.
# ------------------------------------------------------------------------

# Guard
[[ $- == *i* ]] || return 0

### DOCKER ALIASES (originals preserved)

### Lazydocker & Lazyjournal (conditional)
command_check() { command -v "$1" >/dev/null 2>&1; }
if command_check lazydocker; then alias lzd="lazydocker"; fi
if command_check lazyjournal; then alias lzj="lazyjournal"; fi

alias dcp="docker compose -f ~/docker/compose/compose.yml"
alias dci="cd ~/docker/compose && docker compose images"  # Fixed ; → &&
alias dcub="docker compose -f ~/docker/compose/compose.yml up -d --build"

# Consistency: docker compose (v2) everywhere (original mix fixed)
alias dcs="docker compose stop"
alias dcd="docker compose down"
alias dcr="docker compose restart"
alias dcls="docker compose logs"
alias dcl="docker logs -f"
alias dclsf='docker container ls --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}"'
alias dex="docker exec -it"
alias dps="docker ps"
alias dsa="docker ps -q | xargs -r docker stop"
alias dsp="docker system prune -f"
alias dkprune="docker system prune -af"
alias dcpull="docker compose -f ~/docker/compose/compose.yml pull --parallel"
alias dclogs='docker compose -f ~/docker/compose/compose.yml logs -tf --tail=50'
alias dtail='docker logs -tf --tail=50'
alias dkps="docker ps --format '{{.ID}} - {{.Names}} - {{.Status}} - {{.Image}}'"

# FUNCTIONS (originals verbatim + fixes: "$1", returns, locals)

drun() {
    ### Check if container is running
    docker inspect -f '{{.State.Status}}' "$1"
}

did() {
    ### Get container name
    docker inspect --format='{{.Name}}' "$1" | sed 's/^\/>//'
}

dkclean() {
    ### Remove exited containers (orig fixed: local/quote)
    local exited
    exited=$(docker ps -a -q -f status=exited)
    if [[ -n "$exited" ]]; then
        docker rm $exited
    else
        echo "No exited containers to remove"
    fi
}

dcrm() {
    ### Recreate a container (orig logic note preserved)
    docker stop "$1"
    docker rm "$1"
    echo "Container removed. Use 'docker compose up -d $1' to recreate"
}

docker() {
    ### Custom docker wrapper for formatted ps output (orig awk/colors)
    if [[ "$1 $2" = "ps -p" ]]; then
        command docker ps --all --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" \
        | (echo -e "CONTAINER_ID\tNAMES\tIMAGE\tPORTS\tSTATUS"; cat) \
        | awk '{printf "\033[1;32m%s\t\033[01;38;5;95;38;5;196m%s\t\033[00m\033[1;34m%s\t\033[01;90m%s %s %s %s %s %s %s\033[00m\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;}' \
        | column -s$'\\t' -t \
        | sort -k2
    else
        command docker "$@"
    fi
}

dkln() {
    ### Follow logs for named container
    local container
    container=$(docker ps -f name="$1" -q)
    if [[ -z "$container" ]]; then
        echo "No container found with name: $1"
        return 1
    fi
    docker logs -f "$container"
}

dkstats() {
    ### Show docker stats, optionally filtered
    if [[ $# -eq 0 ]]; then
        docker stats --no-stream
    else
        docker stats --no-stream | grep "$1"
    fi
}

dktop() {
    ### Show docker container stats in table format
    docker stats --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

dke() {
    ### Execute shell in container
    docker exec -it "$1" /bin/sh
}

dkexe() {
    ### Execute command in container
    docker exec -it "$1" "$2"
}

dclean() {
    ### Clean up dangling images and volumes
    local images volumes
    images=$(docker images -q -f dangling=true)
    volumes=$(docker volume ls -q -f dangling=true)
    if [[ -n "$images" ]]; then
        docker rmi $images
    else
        echo "No dangling images to remove"
    fi
    if [[ -n "$volumes" ]]; then
        docker volume rm $volumes
    else
        echo "No dangling volumes to remove"
    fi
}

dport() {
    ### Find container using specific port (orig full echo)
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

# Helper function to check Docker
docker_check() {
    if [ ! -x "$(command -v docker)" ]; then
        echo -e "${RED}Error:${NC} Docker is not installed. Please install Docker first." >&2
        return 1
    fi
    if ! docker ps >/dev/null 2>&1; then
        echo "${RED}Error:${NC} Docker daemon is not running. Please start Docker." >&2
        return 1
    fi
    return 0
}

function lzj() {
    if ! docker_check; then return 1; fi
    if [ -n "$TMUX" ]; then
        tmux new-window -n lazyjournal "lazyjournal"
        return
    fi
    if tmux ls >/dev/null 2>&1; then
        tmux new-session -d -s lazyjournal-temp "lazyjournal"
        tmux new-window -t lazyjournal-temp -n lazyjournal "lazyjournal"
        tmux attach-session -t lazyjournal-temp
        return
    fi
    lazyjournal
}

function lzd() {
    if ! docker_check; then return 1; fi
    if [ -n "$TMUX" ]; then
        tmux new-window -n lazydocker "lazydocker"
        return
    fi
    if tmux ls >/dev/null 2>&1; then
        tmux new-session -d -s lazydocker-temp "lazydocker"
        tmux new-window -t lazydocker-temp -n lazydocker "lazydocker"
        tmux attach-session -t lazydocker-temp
        return
    fi
    lazydocker
}
if command_check lazydocker; then alias lzd="lzd"; fi
if command_check lazyjournal; then alias lzj="lzj"; fi
# End - FULL VERBATIM ORIGINAL
