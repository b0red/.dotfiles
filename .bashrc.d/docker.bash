#       Docker alias
#

# Start the docker-compose stack in the current directory
alias dcp="docker-compose -f ~/docker/compose/docker-compose.yml "

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
alias dcl="docker-compose -f log $1"

# Quickly run the docker exec command like this: 'dex container-name bash'
alias dex="docker exec -it $1 /bin/bash"

# 'docker ps' displays the currently running containers
alias dps="docker ps"

# This command is a neat shell pipeline to stop all running containers no matter
# where you are and without knowing any container names
alias dsa="docker ps -q | awk '{print $1}' | xargs -o docker stop"

# Remove stopped containers, unused images, unused networks, etc.:
alias dsp="docker system prune"

###     Docker commands
#
alias dcpull="docker-compose -f ~/docker/compose/docker-compose.yml pull --parallel"
alias dclogs='docker-compose -f ~/docker/compose/docker-compose.yml logs -tf --tail="50" '
alias dtail='docker logs -tf --tail="50" "$@"'
alias dclean="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock zzrot/docker-clean"

