#!/usr/bin/env bash

# Text colors
readonly red="\e[1;31m"
readonly green="\e[1;32m"
readonly yellow="\e[1;33m"
readonly white="\e[1;37m"
readonly normal="\e[m"

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

# ZZ variables treatment. Checks if an environment variable is defined, and ask
# user for value if not.
# After that, save it in docker-compose .env file
# Arguments:
#  [--env-file] env file to write (default to $PREFIX/prozzie/.env)
#  Variable name
#  Default if empty text introduced ("" for error raising)
#  Question text
function zz_variable () {
  if [[ $1 == --env-file=* ]]; then
    local readonly env_file="${1#--env-file=}"
    shift
  else
    local readonly env_file="$PREFIX/prozzie/.env"
  fi

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
    printf "%s=%s\n" "$1" "${!1}" >> "$env_file"
  fi
}

# Default prefix installation path
readonly DEFAULT_PREFIX="/usr/local"
