#!/bin/zsh
# =============================================================================
# Docker Aliases
# Shortcuts for Docker, Docker Compose, and container management
# =============================================================================

# --- Shortcuts ---
# --- Docker Shortcuts ---
alias d='docker'                                     # Alias for the docker command
alias dc='docker-compose'                            # Alias for the docker-compose command
alias dup='docker-compose up -d'                     # Start Docker Compose services in detached mode
alias db='docker-compose up --build -d'              # Build and start Docker Compose services in detached mode
alias ddown='docker-compose down'                    # Stop and remove Docker Compose containers, networks, and volumes
alias dstop='docker-compose stop'                    # Stop Docker Compose services
alias dps='docker ps'                                # List running Docker containers
alias dpsa='docker ps -a'                            # List all Docker containers (running and stopped)
alias dlogs='docker logs -f'                         # Follow logs for Docker services
alias dd='vi docker-compose.yml'                     # Edit the docker-compose.yml file
alias dD='vi Dockerfile'                             # Edit the Dockerfile

# --- Monitoring ---
alias dmem="docker stats --no-stream --format \"table {{.ID}}\t{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\" | sort -k 4 -rh" # Show memory usage of running containers, sorted by percentage

# --- Functions ---
# enter the terminal in a running container with auto prompt with docker names with appropriate shell
function dsh() {
    local selected_container
    selected_container=$(docker ps --format "{{.Names}}" | fzf --prompt="Select container: " --height=40% --layout=reverse --border)

    if [[ -z "$selected_container" ]]; then
        echo "No container selected"
        return 1
    fi

    docker exec -it "$selected_container" /bin/sh
}