# ------------------------------------------------------------------------
#   docker.bash
#   Docker related aliases and functions
# ------------------------------------------------------------------------

# Docker Compose aliases for convenience
alias dcp="docker compose -f ~/docker/compose/compose.yml"
alias dci="cd ~/docker/compose; docker compose images"
alias dcub="docker compose -f ~/docker/compose/compose.yml up -d --build"

# Manage docker-compose stack: stop, down, restart
alias dcs="docker-compose stop"
alias dcd="docker-compose down"
alias dcr="docker restart"

# View container logs with optional service
alias dcls="docker-compose logs"
alias dcl="docker logs -f"
alias dclsf='docker container ls --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}"'

# Execute bash in a container interactively
alias dex="docker exec -it"

# List running containers
alias dps="docker ps"

# Stop all running containers
alias dsa="docker ps -q | xargs -r docker stop"

# Cleanup unused docker resources
alias dsp="docker system prune -f"
alias dkclean="docker rm $(docker ps -a -q -f status=exited)"
alias dkprune="docker system prune -af"

# Docker pull
alias dcpull="docker compose -f ~/docker/compose/compose.yml pull --parallel"

# Logs and stats
alias dclogs='docker compose -f ~/docker/compose/compose.yml logs -tf --tail=50'
alias dtail='docker logs -tf --tail=50'

# Custom docker ps view
alias dkps="docker ps --format '{{.ID}} - {{.Names}} - {{.Status}} - {{.Image}}'"

# Restart and remove container
function dcrm() {
    docker stop "$1"
    docker rm "$1"
    docker start "$1"
}

# Improved docker command with colored ps -p output sorting
function docker() {
    if [ "$1 $2" = "ps -p" ]; then
        command docker ps --all --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" \
            | (echo -e "CONTAINER_ID\tNAMES\tIMAGE\tPORTS\tSTATUS"; cat) \
            | awk '{printf "\033[1;32m%s\t\033[01;38;5;95;38;5;196m%s\t\033[00m\033[1;34m%s\t\033[01;90m%s %s %s %s %s %s %s\033[00m\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;}' \
            | column -s$'\t' -t \
            | sort -k2
    else
        command docker "$@"
    fi
}

# Log viewer by container name
function dkln() {
    local container
    container=$(docker ps -f name="$1" -q)
    docker logs -f "$container"
}

# Stats for container(s), all if no argument
function dkstats() {
    if [ $# -eq 0 ]; then
        docker stats --no-stream
    else
        docker stats --no-stream | grep "$1"
    fi
}

# Show docker stats with table format
function dktop() {
    docker stats --format "table {{.Container}}\t{{.Name}}\t{{CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Execute command in container with /bin/sh shell
function dke() {
    docker exec -it "$1" /bin/sh
}

function dkexe() {
    docker exec -it "$1" "$2"
}

# Clean dangling images and volumes
function dclean() {
    docker rmi $(docker images -q -f dangling=true)
    docker volume rm $(docker volume ls -q -f dangling=true)
}

# Find docker container running on specified port
function dport() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a port number to search for."
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
