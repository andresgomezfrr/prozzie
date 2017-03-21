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

# Check whether OS is debian
if [[ ("$OS" == "Debian" || "$OS" == "Ubuntu") && "$ARCH" == "64" ]]; then

  # Check if docker is installed in current system
  which docker &> /dev/null

  if [[ $? -eq 1 ]]; then
    log error "Docker is not installed!\n"

    log info "Updating apt package index..."
    # Update the apt package index
    sudo apt-get update &> /dev/null
    printf "Done!\n"
    log info "Checking and installing necessary tools..."
    # Install curl tool
    sudo apt-get install -y curl &> /dev/null
    printf "Done!\n"

    log info "Initializing docker installation!\n"
    # Install packages to allow apt to use repository over HTTPS
    log info "Installing packages to allow apt to use repository over HTTPS..."
    sudo apt-get install -y \
      apt-transport-https \
      ca-certificates &> /dev/null
    printf "Done!\n"
    # Ubuntu distributions
    if [[ "$OS" == "Ubuntu" ]]; then

      if [[ "$VER" == 1[46].* ]]; then

        # Version 14.04 (Trusty)
        if [[ "$VER" == "14.04"  ]]; then
          sudo apt-get install -y \
            linux-image-extra-$(uname -r) \
            linux-image-extra-virtual &> /dev/null
        fi

        sudo apt-get install -y software-properties-common &> /dev/null

        # Add Docker's official GPG key
        log info "Adding Docker's official GPG key..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
        printf "Done!\n"

        # Set up the stable repository
        log info "Setting up Docker's stable repository..."
        sudo add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable" &> /dev/null
        printf "Done!\n"

      fi # Ubuntu version

    else # Debian distributions

      if [[ "$VER" == [78].* ]]; then

        # Install packages to allow apt to use a repository over HTTPS:
        if [[ "$NAME" == "wheezy" ]]; then
           sudo apt-get install -y python-software-properties &> /dev/null
        elif [[ "$NAME" == "stretch" || "$NAME" == "jessie" ]]; then
           sudo apt-get install -y software-properties-common &> /dev/null
        fi

        # Add Docker’s official GPG key:
        log info "Adding Docker's official GPG key..."
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - &> /dev/null
        printf "Done!\n"

        # Set up the stable repository
        log info "Setting up Docker's stable repository..."
        sudo add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/debian \
          $(lsb_release -cs) \
          stable" &> /dev/null
        printf "Done!\n"

      fi # Debian version

    fi # OS Debian

    # Update the apt package index
    sudo apt-get update &> /dev/null

    # Install the latest version of Docker Community Edition
    log info "Installing the latest version of Docker Community Edition..."
    sudo apt-get install -y docker-ce &> /dev/null
    printf " Done!\n\n"

    # Configure Docker to start boot
    read -p "Do you want that docker to start on boot? [y/N]: " -n 1 -r
    printf "\n\n"

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo systemctl enable docker &> /dev/null
      log ok "Configured docker to start on boot!\n"
    fi

  fi # Docker installation

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
    if [[ "$OS" == "Ubuntu" ]]; then
      if ! [[ "$VER" == 1[46].* ]]; then
        log error "You need Ubuntu 16.10, 16.04 or 14.04. Your current Ubuntu version is: $VER"
      fi
    elif [[ "$OS" == "Debian" ]]; then
      if ! [[ "$VER" == [87].* ]]; then
        log error "You need Debian 8.0 or 7.7. Your current Debian version is: $VER"
      fi
    else
      log error "This linux distribution is not supported! You need Ubuntu or Debian linux distribution\n"
    fi
  fi
fi
