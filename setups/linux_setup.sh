#!/bin/bash
# Clear screen
clear

# Text colors
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
white="\e[1;37m"
normal="\e[m"

# Operative System
OS=$(lsb_release -si)
# Architecture
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
# OS Version
VER=$(lsb_release -sr)
# OS Name
NAME=$(lsb_release -sc)
# List of needed depedencies for prozzie
NEEDED_DEPENDENCIES="curl jq wget unzip"
# List of installed dependencies
INSTALLED_DEPENDENCIES=""
# Package manager for install, uninstall and update
PKG_MANAGER=""

# log function
function log {
  case $1 in
    e|error|erro) # ERROR
      printf "[ ${red}ERRO${normal} ] $2"
      ;;
    i|info) # INFORMATION
      printf "[ ${white}INFO${normal} ] $2"
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

function show_banner {
  printf " __          ___         _        _____                  _      \n \ \        / (_)       (_)      |  __ \                (_)     \n  \ \  /\  / / _ _________  ___  | |__) | __ ___ _________  ___ \n   \ \/  \/ / | |_  /_  / |/ _ \ |  ___/ '__/ _ \_  /_  / |/ _ \ \n    \  /\  /  | |/ / / /| |  __/ | |   | | | (_) / / / /| |  __/\n     \/  \/   |_/___/___|_|\___| |_|   |_|  \___/___/___|_|\___|\n\n"
}

# Install a program
function install {
    log info "Installing $1 dependency..."
    sudo $PKG_MANAGER install -y $1 &> /dev/null
    printf "Done!\n"
}

# Uninstall a program
function uninstall {
    log info "Uninstalling $1 dependency..."
    sudo $PKG_MANAGER remove -y $1 &> /dev/null
    printf "Done!\n"
}

# Update repository
function update {

  case $PKG_MANAGER in
    apt-get) # Ubuntu/Debian
      log info "Updating apt package index..."
      sudo $PKG_MANAGER update &> /dev/null
      printf "Done!\n"
    ;;
    yum) # CentOS
      log info "Updating yum package index..."
      sudo $PKG_MANAGER makecache fast &> /dev/null
      printf "Done!\n"
    ;;
    dnf) # Fedora
      log info "Updating dnf package index..."
      sudo $PKG_MANAGER makecache fast &> /dev/null
      printf "Done!\n"
    ;;
    *)
      log error "Usage: update"
    ;;
  esac

}

# Show "Wizzie Prozzie" banner
show_banner

# Print user system information
printf "System information: \n\n"
printf "  OS: $OS \n  Version: $VER \n  Name: $NAME\n\n"

# Check architecture
if [[ $ARCH -eq 64 ]]; then

  # Set PKG_MANAGER first time
  case $OS in
    Debian|Ubuntu)
      PKG_MANAGER="apt-get"
    ;;
    CentOS)
      PKG_MANAGER="yum"
    ;;
    Fedora)
      PKG_MANAGER="dnf"
    ;;
  esac

  # Update repository
  update

  # Install needed dependencies
  for DEPENDENCY in $NEEDED_DEPENDENCIES; do

    # Check if dependency is installed in current OS
    type $DEPENDENCY &> /dev/null

    if [[ $? -eq 1 ]]; then

      # CentOS systems only
      if [[ $DEPENDENCY == jq && $OS == CentOS ]]; then
        install epel-release
      fi

      install $DEPENDENCY
      INSTALLED_DEPENDENCIES="$INSTALLED_DEPENDENCIES $DEPENDENCY"
    fi
  done

  # Check if docker is installed in current OS
  type docker &> /dev/null

  if [[ $? -eq 1 ]]; then
    log warn "Docker is not installed!\n"
    log info "Initializing docker installation!\n"

    if [[ $OS =~ ^(Ubuntu|Debian)$ ]]; then
      log info "Installing packages to allow apt to use repository over HTTPS..."
      sudo apt-get install -y \
        apt-transport-https \
        ca-certificates &> /dev/null
      printf "Done!\n"
    fi

    # Install docker dependencies
    case $OS in
      Debian)
          if [[ $VER == [87].* ]]; then

            # Install packages to allow apt to use a repository over HTTPS:
            if [[ "$NAME" == "wheezy" ]]; then
               install python-software-properties &> /dev/null
            elif [[ "$NAME" == "stretch" || "$NAME" == "jessie" ]]; then
               install software-properties-common &> /dev/null
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

          else
            log error "You need Debian 8.0 or 7.7. Your current Debian version is: $VER"
          fi
      ;;
      Ubuntu)
          if [[ $VER == 1[46].* ]]; then

            # Version 14.04 (Trusty)
            if [[ $VER == 14.04  ]]; then
              sudo apt-get install -y \
                linux-image-extra-$(uname -r) \
                linux-image-extra-virtual &> /dev/null
            fi

            # Install Docker's dependencies
            log info "Installing docker dependencies..."
            install software-properties-common &> /dev/null
            printf "Done!\n"

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

          else
            log error "You need Ubuntu 16.10, 16.04 or 14.04. Your current Ubuntu version is: $VER"
          fi
      ;;
      CentOS)
          if [[ $VER == 7.* ]]; then

            log info "Installing necessary packages for set up repository..."
            install yum-utils &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            sudo yum-config-manager \
                 --add-repo \
                 https://download.docker.com/linux/centos/docker-ce.repo &> /dev/null
            printf "Done!\n"

          else
            log error "You need CentOS 7. Your current CentOS version is: $VER"
          fi
      ;;
      Fedora)
          if [[ $VER =~ 2[45] ]]; then

            # Update repository
            update

            log info "Installing necessary packages for set up repository..."
            install dnf-plugins-core &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            sudo dnf config-manager \
                 --add-repo \
                 https://download.docker.com/linux/fedora/docker-ce.repo &> /dev/null
            printf "Done!\n"

          else
            log error "You need Fedora 24 or 25. Your current Fedora version is: $VER"
          fi
      ;;
      *)
            log error "This linux distribution is not supported! You need Ubuntu, Debian, Fedora or CentOS linux distribution\n"
      ;;
    esac

    # Update repository
    update

    log info "Installing the latest version of Docker Community Edition..."
    $PKG_MANAGER install -y docker-ce &> /dev/null;
    printf "Done!\n\n"

    # Configure Docker to start boot
    read -p "Do you want that docker to start on boot? [Y/n]: " -n 1 -r
    printf "\n\n"

    if [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]]; then
      case $OS in
        Debian|Ubuntu)
          sudo systemctl enable docker &> /dev/null
        ;;
        Fedora|CentOS)
          sudo systemctl start docker &> /dev/null
        ;;
      esac
      log ok "Configured docker to start on boot!\n"
    fi # Check if user response {Y}es

  fi # Check if docker is installed

  # Installed docker version
  DOCKER_VERSION=$(docker -v) 2> /dev/null
  log ok "Installed: $DOCKER_VERSION\n"

  # Check if docker-compose is installed in current OS
  type docker-compose &> /dev/null

  if [[ $? -eq 1 ]]; then
    log warn "Docker-Compose is not installed!\n"
    log info "Initializing Docker-Compose installation\n"
    # Download latest release (Not for production)
    log info "Downloading latest release of Docker Compose..."
    sudo curl -s -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &> /dev/null
    # Add permissions
    sudo chmod +x /usr/local/bin/docker-compose &> /dev/null
    printf "Done!\n"
  fi

  # Get installed docker-compose version
  DOCKER_COMPOSE_VERSION=$(docker-compose --version) 2> /dev/null
  log ok "Installed: $DOCKER_COMPOSE_VERSION\n\n"

  # Download of prozzie and installation
  log info "Downloading latest release of Prozzie..."
  wget $(curl -sL http://api.github.com/repos/wizzie/prozzie/releases/latest | jq .assets[0].browser_download_url | sed "s/\"//g") -O prozzie.zip &> /dev/null
  printf "Done!\n"

  log info "Decompressing..."
  unzip -j -q -o prozzie.zip -d prozzie &> /dev/null ; rm -rf prozzie.zip
  printf "Done!\n\n"

  # Check installed dependencies
  if ! [[ -z "$INSTALLED_DEPENDENCIES" ]]; then
    log info "This script has installed next dependencies: $INSTALLED_DEPENDENCIES\n\n"

    read -p  "They are no longer needed. Would you like to uninstall? [y/N]: " -n 1 -r
    printf "\n\n"

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Uninstall dependencies
      for DEPENDENCY in $INSTALLED_DEPENDENCIES; do
        uninstall $DEPENDENCY
      done
      log info "All Prozzie dependecies have been uninstalled!\n"
    fi

  fi

  # Start prozzie...
  log info "Starting Prozzie...\n\n"
  docker-compose up

else
  log error "You need 64 bits OS. Your current architecture is: $ARCH"
fi
