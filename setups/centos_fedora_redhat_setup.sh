#!/bin/bash
# Clear screen
clear

# Text colors
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
normal="\e[m"

# Operative System
OS=$(lsb_release -si)
# Architecture
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
# OS Version
VER=$(lsb_release -sr)
# OS Name
NAME=$(lsb_release -sc)

# log function
function log {
  case $1 in
    e|error|erro) # ERROR
      printf "[ ${red}ERRO${normal} ] $2"
      ;;
    i|info) # INFORMATION
      printf "[ INFO ] $2"
    ;;
    w|warn) # WARNING
      printf "[ ${yellow}WARN${normal} ] $2"
    ;;
    f|fail) # FAIL
      printf "[ ${red}FAIL${normal} ] $2"
    ;;
    o|ok) # OK
      printf "[  ${green}OK${normal}  ] $2"
    ;;
    *) # USAGE
      printf "Usage: log [i|e|w|f] <message>"
    ;;
  esac
}

printf "System information: \n\n"
printf "  OS: $OS \n  Version: $VER \n  Name: $NAME\n\n"

if [[ "$VER" == "^7\..+" ]]; then
  log error "You need CentOS 7. Your current CentOS version is: $VER"
fi

# Check whether OS is fedora or centos
# TODO: Add support for RedHat!
if [[ ("$OS" == "CentOS" || "$OS" == "Fedora") && "$ARCH" == "64" ]]; then

  # Check if docker is installed in current OS
  type docker &> /dev/null

  if [[ $? -eq 1 ]]; then
    log error "Docker is not installed!\n"
    log info "Initializing docker installation!\n"

    # CentOS
    if [[ "$OS" == "CentOS" ]]; then

      if [[ "$VER" == 7.* ]]; then

        log info "Updating yum package index..."
        # Update the yum package index
        sudo yum makecache fast &> /dev/null
        printf "Done!\n"

        log info "Checking and installing necessary tools..."
        # Install curl tool
        sudo yum install -y curl &> /dev/null
        printf "Done!\n"

        log info "Installing necessary packages for set up repository..."
        sudo yum install -y yum-utils &> /dev/null
        printf "Done!\n"

        # Set up the stable repository
        log info "Setting up Docker's stable repository..."
        sudo yum-config-manager \
             --add-repo \
             https://download.docker.com/linux/centos/docker-ce.repo &> /dev/null
        printf "Done!\n"

        sudo yum makecache fast &> /dev/null

        # Install the latest version of Docker Community Edition
        log info "Installing the latest version of Docker Community Edition..."
        sudo yum install -y docker-ce &> /dev/null
        printf " Done!\n\n"

      fi

    else # Fedora distributions

      # To install Docker, you need the 64-bit version of one of these Fedora versions:
      if [[ "$VER" == 2[45] ]]; then
        log info "Updating dnf package index..."
        # Update the dnf package index
        sudo dnf makecache fast &> /dev/null
        printf "Done!\n"

        log info "Installing necessary packages for set up repository..."
        sudo dnf install -y dnf-plugins-core &> /dev/null
        printf "Done!\n"

        # Set up the stable repository
        log info "Setting up Docker's stable repository..."
        sudo dnf config-manager \
             --add-repo \
             https://download.docker.com/linux/fedora/docker-ce.repo &> /dev/null
        printf "Done!\n"

        dnf makecache fast &> /dev/null

        # Install the latest version of Docker Community Edition
        log info "Installing the latest version of Docker Community Edition..."
        sudo dnf install -y docker-ce &> /dev/null
        printf "Done!\n\n"
      fi

    fi

    # Configure Docker to start boot
    read -p "Do you want that docker to start on boot? [y/N]: " -n 1 -r
    printf "\n\n"

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo systemctl start docker &> /dev/null
      log ok "Configured docker to start on boot!\n"
    fi

  fi

  DOCKER_VERSION=$(docker -v) 2> /dev/null

  log ok "Installed: $DOCKER_VERSION\n"

  # Check if docker-compose is installed in current system
  which docker-compose &> /dev/null

  if [[ $? -eq 1 ]]; then
    log error "Docker-Compose is not installed!\n"
    # Create directory
    # sudo mkdir -p /usr/local/bin/docker-compose
    log info "Initializing Docker-Compose installation\n"
    # Download latest release (Not for production)
    log info "Downloading latest release of Docker Compose..."
    sudo curl -s -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &> /dev/null
    # Add permissions
    sudo chmod +x /usr/local/bin/docker-compose &> /dev/null
    printf "Done!\n"
  fi

  DOCKER_COMPOSE_VERSION=$(docker-compose --version) 2> /dev/null

  log ok "Installed: $DOCKER_COMPOSE_VERSION\n\n"

  # TODO: Add check for git command
  log info "Getting latest version of prozzie..."
  git fetch --tags &> /dev/null
  git describe --tags &> /dev/null

  if [[ $? -eq 128 ]]; then
    printf "Done!\n"
    log warn "Not prozzie stable releases found!\n"
  else
    LATEST_STABLE_PROZZIE=$(git describe --tags `git rev-list --tags --max-count=1`) 2> /dev/null
    git checkout $LATEST_STABLE_PROZZIE &> /dev/null
    printf "Done!\n"
    log info "Starting prozzie: \n"
    docker-compose up
  fi

else # ERRORS
    if ! [[ "$ARCH" == "64"  ]]; then
      log error "You need 64 bits OS. Your current architecture is: $ARCH"
    else
      if [[ "$OS" == "CentOS" ]]; then
        if ! [[ "$VER" == "^7\..+" ]]; then
          log error "You need CentOS 7. Your current CentOS version is: $VER"
        fi
      elif [[ "$OS" == "Fedora" ]]; then
        if ! [[ "$VER" == 2[45] ]]; then
          log error "You need Fedora 24 or 25. Your current Fedora version is: $VER"
        fi
      else
        log error "This linux distribution is not supported! You need Fedora or CentOS linux distribution \n"
      fi
    fi
fi
