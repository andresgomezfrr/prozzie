#!/bin/bash
# Clear screen
clear

# Text colors
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
white="\e[1;37m"
normal="\e[m"

. /etc/os-release

# Architecture
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

# List of needed depedencies for prozzie
NEEDED_DEPENDENCIES="curl jq wget unzip net-tools"
# List of installed dependencies
INSTALLED_DEPENDENCIES=""
# Package manager for install, uninstall and update
PKG_MANAGER=""

ID=${ID,,}

# Prefix installation path
readonly DEFAULT_PREFIX="/usr/local"

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

# Wizzie Prozzie banner! :D
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
      log error "Usage: update\n"
    ;;
  esac

}

# ZZ variables treatment. Checks if an environment variable is defined, and ask
# user for value if not.
# After that, save it in docker-compose .env file
# Arguments:
#  Variable name
#  Default if empty text introduced ("" for error raising)
#  Question text
function zz_variable () {
  if [[ -z "${!1}" ]]; then
    read -p "$3" $1
  fi

  if [[ -z "${!1}" ]]; then
    if [[ ! -z "$2" ]]; then
      read $1 <<< $2
    else
      log fail "[${!1}][$2] Empty $1 not allowed"
      exit 1
    fi
  fi

  if [[ $1 != PREFIX ]]; then
    echo "$1=${!1}" >> "$PREFIX/prozzie/.env"
  fi
}

if [[ $EUID -ne 0 ]]; then
  log warn "You must be a root user for running this script. Please use sudo\n"
  exit 1
fi

# Show "Wizzie Prozzie" banner
show_banner

# Print user system information
printf "System information: \n\n"
printf "  OS: $PRETTY_NAME\n  Architecture: $ARCH\n\n"

# Check architecture
if [[ $ARCH -eq 64 ]]; then

  zz_variable PREFIX "${DEFAULT_PREFIX}" "Where do you want install prozzie? [${PREFIX}] (You can set path to $HOME/.local if you don't have privileges): "

  if [[ ! -d "$PREFIX" ]]; then
    log error "The directory [$PREFIX] doesn't exist. Re-run Prozzie installer and enter a valid path.\n"
    exit 1
  fi

  log info "Prozzie will be installed in: [$PREFIX]\n"

  # Set PKG_MANAGER first time
  case $ID in
    debian|ubuntu)
      PKG_MANAGER="apt-get"
    ;;
    centos)
      PKG_MANAGER="yum"
    ;;
    fedora)
      PKG_MANAGER="dnf"
    ;;
    *)
      log error "This linux distribution is not supported! You need Ubuntu, Debian, Fedora or CentOS linux distribution\n"
      exit 1
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
      if [[ $DEPENDENCY == jq && $ID == centos ]]; then
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

    if [[ $ID =~ ^\"?(ubuntu|debian)\"?$ ]]; then
      log info "Installing packages to allow apt to use repository over HTTPS..."
      sudo apt-get install -y \
        apt-transport-https \
        ca-certificates &> /dev/null
      printf "Done!\n"
    fi

    # Install docker dependencies
    case $ID in
      debian)
          if [[ $VERSION_ID =~ ^\"?[87].*\"?$ ]]; then

            # Install packages to allow apt to use a repository over HTTPS:
            if [[ ${VERSION,,} =~ ^\"?.*whezzy.*\"?$ ]]; then
               install python-software-properties &> /dev/null
            elif [[ ${VERSION,,} =~ ^\"?.*stretch.*\"?$ || $VERSION =~ ^\"?.*jessie.*\"?$ ]]; then
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
            log error "You need Debian 8.0 or 7.7. Your current Debian version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      ubuntu)
          if [[ $VERSION_ID =~ ^\"?1[46].*\"?$ ]]; then

            # Version 14.04 (Trusty)
            if [[ ${VERSION_ID,,} =~ ^\"?.*trusty.*\"?$  ]]; then
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
            log error "You need Ubuntu 16.10, 16.04 or 14.04. Your current Ubuntu version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      centos)
          if [[ $VERSION_ID =~ ^\"?7.*\"?$ ]]; then

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
            log error "You need CentOS 7. Your current CentOS version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      fedora)
          if [[ $VERSION_ID =~ ^\"?2[45]\"?$ ]]; then

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
            log error "You need Fedora 24 or 25. Your current Fedora version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      *)
            log error "This linux distribution is not supported! You need Ubuntu, Debian, Fedora or CentOS linux distribution\n"
            exit 1
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
      case $ID in
        debian|ubuntu)
          sudo systemctl enable docker &> /dev/null
        ;;
        fedora|centos)
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
    sudo curl -s -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose &> /dev/null
    # Add permissions
    sudo chmod +x /usr/bin/docker-compose &> /dev/null
    printf "Done!\n"
  fi

  # Get installed docker-compose version
  DOCKER_COMPOSE_VERSION=$(docker-compose --version) 2> /dev/null
  log ok "Installed: $DOCKER_COMPOSE_VERSION\n\n"

  # Download of prozzie and installation
  log info "Downloading latest release of Prozzie..."
  wget $(curl -sL http://api.github.com/repos/wizzie-io/prozzie/releases/latest?access_token=4ea54f05cd7111c2e886f2c26f59b99109245053 | jq '(.zipball_url + "?access_token=4ea54f05cd7111c2e886f2c26f59b99109245053")'| sed 's|[",]||g') -O prozzie.zip &> /dev/null
  printf "Done!\n"

  log info "Decompressing..."
  unzip -qj -o prozzie.zip -d "$PREFIX/prozzie" &> /dev/null ; rm -rf prozzie.zip
  printf "Done!\n"
  rm -f "$PREFIX/prozzie/.env"

  read -p "Do you want discover the IP address automatically? [Y/n]: " -n 1 -r
  printf "\n"

  if [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]]; then
    MAIN_INTERFACE=$(route -n | awk '{printf("%s %s\n", $1, $8)}' | grep 0.0.0.0 | awk '{printf("%s", $2)}')
    INTERFACE_IP=$(ifconfig ${MAIN_INTERFACE} | grep inet | grep -v inet6 | awk '{printf("%s", $2)}' | sed 's/addr://')
  fi

  zz_variable INTERFACE_IP $INTERFACE_IP '' "Introduce the IP address: "
  printf "\n\n"

  zz_variable CLIENT_API_KEY   '' "Introduce your client API key: "
  zz_variable ZZ_HTTP_ENDPOINT '' "Introduce the data HTTP endpoint URL: "

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

  log info "Adding start and stop scripts..."

  # Create prozzie/bin directory
  mkdir -p "$PREFIX/prozzie/bin"

  echo -e "#!/bin/bash\n\n(cd $PREFIX/prozzie ; docker-compose start)" > "$PREFIX/prozzie/bin/start-prozzie.sh"
  sudo chmod +x "$PREFIX/prozzie/bin/start-prozzie.sh"

  echo -e "#!/bin/bash\n\n(cd $PREFIX/prozzie; docker-compose stop)" > "$PREFIX/prozzie/bin/stop-prozzie.sh"
  sudo chmod +x "$PREFIX/prozzie/bin/stop-prozzie.sh"

  echo -e "#!/bin/bash\n\n(docker run -it -e KAFKA_CONNECT_REST=http://${INTERFACE_IP}:8083 gcr.io/wizzie-registry/kafka-connect-cli:1.0.1 sh -c \"kcli \$@\")" > "$PREFIX/prozzie/bin/kcli.sh"
  sudo chmod +x "$PREFIX/prozzie/bin/kcli.sh"

  printf "Done!\n\n"

  if [[ ! -f /usr/bin/prozzie-start ]]; then
    sudo ln -s "$PREFIX/prozzie/bin/start-prozzie.sh" /usr/bin/prozzie-start
  fi

  if [[ ! -f /usr/bin/prozzie-stop ]]; then
    sudo ln -s "$PREFIX/prozzie/bin/stop-prozzie.sh" /usr/bin/prozzie-stop
  fi

  if [[ ! -f /usr/bin/kcli ]]; then
    sudo ln -s "$PREFIX/prozzie/bin/kcli.sh" /usr/bin/kcli
  fi

  log ok "Prozzie installation is finished!\n"
  log info "Starting Prozzie...\n\n"

  (cd "$PREFIX/prozzie"; \
  docker-compose up)

else
  log error "You need 64 bits OS. Your current architecture is: $ARCH"
fi
