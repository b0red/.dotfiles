#       Docker alias
#

# Start the docker-compose stack in the current directory
alias dcp="docker-compose -f ~/docker/compose/docker-compose.yml up -d"

# Start the docker-compose stack in the current directory and rebuild the images
alias dcub="~/docker/compose/docker-compose up -d --build"

# Stop, delete (down) or restart the docker-compose stack in the current directory
alias dcs="docker-compose stop $1"
alias dcd="docker-compose down"
alias dcr="docker-compose restart"

# Show the logs for the docker-compose stack in the current directory
# May be extended with the service name to get service-specific logs, like
# 'dcl php' to get the logs of the php container
alias dcls="docker-compose logs"
alias dcl="docker logs -f $1"

# Quickly run the docker exec command like this: 'dex container-name bash'
alias dex="docker exec -it $1 /bin/bash"

# 'docker ps' displays the currently running containers
alias dps="docker ps"

# This command is a neat shell pipeline to stop all running containers no matter
# where you are and without knowing any container names
alias dsa="docker ps -q | awk '{print $1}' | xargs -o docker stop"

# Remove stopped containers, unused images, unused networks, etc.:
alias dsp="docker system prune"

# stop and remove image(s)
alias drm="docker stop $1; docker rm $1; docker image prune -a"

###     Docker commands
#
alias dcpull="docker-compose -f ~/docker/compose/docker-compose.yml pull --parallel"
alias dclogs='docker-compose -f ~/docker/compose/docker-compose.yml logs -tf --tail="50" '
alias dtail='docker logs -tf --tail="50" "$@"'
alias dclean="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock zzrot/docker-clean"

###
#
alias dkps="docker ps --format '{{.ID}} - {{.Names}} - {{.Status}} - {{.Image}}'"

###     Docker functions
# remove a container and restart
#
function dcrm() {
    docker stop $1
    docker rm $1
    docker start $1 
}

function docker () {
    if [[ "$@" == "ps -p" ]]; then
        command docker ps --all --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" \
            | (echo -e "CONTAINER_ID\tNAMES\tIMAGE\tPORTS\tSTATUS" && cat) \
            | awk '{printf "\033[1;32m%s\t\033[01;38;5;95;38;5;196m%s\t\033[00m\033[1;34m%s\t\033[01;90m%s %s %s %s %s %s %s\033[00m\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;}' \
            | column -s$'\t' -t \
            | awk 'NR<2{print $0;next}{print $0 | "sort --key=2"}'
    else
        command docker "$@"
    fi
}

# https://medium.com/hackernoon/handy-docker-aliases-4bd85089a3b8
# view the log for any container by name
function dkln() {
    docker logs -f `docker pf | grep $1 | awk {print $1}`
}

# View stats for a container
# https://techietown.info/2017/03/docker-container-monitoring-using-docker-stats/
function dkstats() {
    if [ $# -eq 0 ]
        then docker stats --no-stream;
        else docker stats --no-stream | grep $1;
    fi
}

# Show tops stats for memory, cpu, network i/o, block i/o
# https://techietown.info/2017/03/docker-container-monitoring-using-docker-stats/
function dktop() {
    docker stats --format "table {{.Container}}\t{{.Name}}\t{{CPUPerc}}  {{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

function dkclean() {
  docker rm $(docker ps --all -q -f status=exited)
  docker volume rm $(docker volume ls -qf dangling=true)
}

function dkprune() {
  docker system prune -af
}

dke() {
  docker exec -it $1 /bin/sh
}

dkexe() {
  docker exec -it $1 $2
}
