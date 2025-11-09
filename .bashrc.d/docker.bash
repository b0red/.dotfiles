# ------------------------------------------------------------------------
#   docker.bash
#   Docker related aliases and functions
# ------------------------------------------------------------------------
###     DOCKER ALIASES
#
###     Lazydocker
#
if command_check lazydocker; then alias lzd="lazydocker"; fi
# Removed duplicate lzd alias - keep only one or the other

alias dcp="docker compose -f ~/docker/compose/compose.yml"
alias dci="cd ~/docker/compose && docker compose images"  # Changed ; to &&
alias dcub="docker compose -f ~/docker/compose/compose.yml up -d --build"

# INCONSISTENT: Some use docker-compose (old), some use docker compose (new)
# Recommend using 'docker compose' everywhere for consistency:
alias dcs="docker compose stop"
alias dcd="docker compose down"
alias dcr="docker compose restart"  # Added 'compose' for consistency

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

# Aliases can't use positional parameters ($1). Convert to functions:
function drun() {
    ### Check if container is running
    docker inspect -f '{{.State.Status}}' "$1"
}

function did() {
    ### Get container name
    docker inspect --format='{{.Name}}' "$1" | sed 's/^\/\?//'
}

# POTENTIAL ERROR: These commands might fail if no containers match
function dkclean() {
    ### Remove exited containers
    local exited
    exited=$(docker ps -a -q -f status=exited)
    if [ -n "$exited" ]; then
        docker rm $exited
    else
        echo "No exited containers to remove"
    fi
}

# LOGIC ERROR: This function won't work as intended
function dcrm() {
    ### Recreate a container
    docker stop "$1"
    docker rm "$1"
    # Can't start a removed container - should use 'docker compose up -d' or similar
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
    local container
    container=$(docker ps -f name="$1" -q)
    if [ -z "$container" ]; then
        echo "No container found with name: $1"
        return 1
    fi
    docker logs -f "$container"
}

function dkstats() {
    ### Show docker stats, optionally filtered
    if [ $# -eq 0 ]; then
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
    docker exec -it "$1" /bin/sh
}

function dkexe() {
    ### Execute command in container
    docker exec -it "$1" "$2"
}

function dclean() {
    ### Clean up dangling images and volumes
    local images volumes
    images=$(docker images -q -f dangling=true)
    volumes=$(docker volume ls -q -f dangling=true)
    
    if [ -n "$images" ]; then
        docker rmi $images
    else
        echo "No dangling images to remove"
    fi
    
    if [ -n "$volumes" ]; then
        docker volume rm $volumes
    else
        echo "No dangling volumes to remove"
    fi
}

function dport() {
    ### Find container using specific port
    if [ -z "$1" ]; then
        echo "Usage: dport <port>"
        return 1
    fi
    local port_to_find="$1"
    local result
    result=$(docker ps --format "{{.ID}}\t{{.Names}}\t{{.Ports}}" | grep "$port_to_find")
    if [ -z "$result" ]; then
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