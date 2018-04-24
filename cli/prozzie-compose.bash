#!/usr/bin/env bash

# Prozzie - Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Script: Forward a specified command to prozzie docker-compose.
# Arguments:
#  (All will be forwarded to docker-compose)
#
# Environment:
#  PREFIX - prozzie config files should be in $PREFIX/etc/prozzie/compose
#
# Out:
#  -
#
# Exit status:
#  -

declare -r script_name=$(basename -s '.bash' "$0")

if [[ $# -gt 0 && ($1 == '--shorthelp' || $1 == '--help' ) ]]; then
    declare message
    case "${script_name}" in
    prozzie-start)
        message='Start prozzie services'
        ;;
    prozzie-stop)
        message='Stop prozzie services'
        ;;
    prozzie-up)
        message='(re)Create and start prozzie services'
        ;;
    prozzie-down)
        message='Stop prozzie services and remove kafka queue'
        ;;
    prozzie-logs)
        message='View output from connectors'
        ;;
    prozzie-compose|*)
        message='Send generic commands to prozzie docker compose'
        ;;
    esac
    printf '%s\n' "$message"
    exit 0
fi

declare action="${script_name#prozzie-}"
if [[ $action == 'compose' ]]; then
    unset -v action
fi

# Needed for .env file location
cd "${PREFIX}/etc/prozzie" # TODO test docker-compose --project-directory
docker-compose \
    --project-name prozzie \
    --file "${PREFIX}/share/prozzie/docker-compose.yml" ${action} "$@"
