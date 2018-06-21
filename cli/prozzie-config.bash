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

# Includes
. "${BASH_SOURCE%/*}/include/common.bash"
. "${BASH_SOURCE%/*}/include/config.bash"
. "${BASH_SOURCE%/*}/include/cli.bash"

# Declare prozzie cli config directory path
declare -r PROZZIE_CLI_CONFIG="${BASH_SOURCE%/*}/config"
declare -r PROZZIE_ENVS="${PREFIX:-${DEFAULT_PREFIX}}/etc/prozzie/envs"

# .env file path
declare base_env_file="${PREFIX:-${DEFAULT_PREFIX}}/etc/prozzie/.env"

printShortHelp() {
    printf "Handle prozzie configuration\n"
}

printUsage() {
    declare -A commands_and_descriptions=(
        ["-w, --wizard"]="Start modules wizard"
        ["-d, --describe <module>"]="Describe module vars"
        ["-s, --setup <module>"]="Configure module with setup assistant"
        ["--describe-all"]="Describe all modules vars"
        ["--enable <modules-list>"]="Enable modules"
        ["--disable <modules-list>"]="Disable modules"
        ["-h, --help"]="Show this help"
        ["--list-enables"]="List all enables modules"
    )

    declare -a order=(
        "-w, --wizard"
        "-d, --describe <module>"
        "-s, --setup <module>"
        "--describe-all"
        "--enable <modules-list>"
        "--disable <modules-list>"
        "--list-enables"
        "-h, --help"
    )

    printf "usage: prozzie config <module> [key] [value]\n"
    printf "   or: prozzie config <option> [args]\n"
    printf "\nAvailable options are:\n"

    for comm in "${order[@]}"
    do
        help_command_format "$comm" "${commands_and_descriptions[$comm]}"
    done
}

help_command_format() {
    printf "\t%-40s%s\n" "$1" "$2"
}

describeModule () {
    declare -r module="$1"

    if [[ ! -f "$PROZZIE_CLI_CONFIG/$module.bash" ]]; then
        printf "Module '%s' not found!\n" "$module" >&2
        return 1
    fi

    . "$PROZZIE_CLI_CONFIG/$module.bash"
    showVarsDescription
    return 0
}

main() {
    declare -r option_regex="^--?(.+)$"
    declare option
    declare module

    # Show help if options are not present
    if [[ $# -eq 0 ]]; then
        printUsage
        exit 0
    fi

    # Try parse option
    if [[ "$1" =~ $option_regex ]]; then
        option=${BASH_REMATCH[1]} # Get option
    else # It's a posible module
        module="$1"
    fi

    shift
    if [[ $option ]]; then
        case $option in
            shorthelp)
                printShortHelp
                exit 0
            ;;
            h|help)
                printShortHelp
                printUsage
                exit 0
            ;;
            w|wizard)
                wizard "$src_env_file"
                exit 0
            ;;
            d|describe)
                module="$1"
                if [[ $module ]]; then
                    printf "Module ${module}: \n"
                    describeModule "$module" && exit 0 || exit 1
                fi
                printUsage
                exit 1
            ;;
            describe-all)
                declare -r prefix="*/cli/config/"
                declare -r suffix=".bash"

                for config_module in "$PROZZIE_CLI_CONFIG"/*.bash; do
                    . "$config_module"

                    config_module=${config_module#$prefix}
                    printf "Module ${config_module%$suffix}: \n"

                    showVarsDescription
                done
                exit 0
            ;;
            s|setup)
                module="$1"
                if [[ -f "$PROZZIE_CLI_CONFIG/$module.bash" ]]; then
                    . "$PROZZIE_CLI_CONFIG/$module.bash"
                    if [[ $module =~ ^(mqtt|syslog)$ ]]; then
                        . "${BASH_SOURCE%/*}/include/kcli_base.bash"
                        tmp_fd properties
                        kcli_setup "/dev/fd/${properties}" "$module"
                        exec {properties}<&-
                    else
                        ENV_FILE="$PROZZIE_ENVS/$module.env"
                        printf "Setup %s module:\n" "$module"
                        shift
                        app_setup "$module"
                    fi
                    exit 0
                fi
                printUsage
                exit 1
            ;;
            enable|disable)
                zz_enable_disable_modules "$option" "$@"
                exit 0
            ;;
            list-enables)
                zz_list_enable_modules
                exit 0
            ;;
            *)
                printf "error: unknown option '%s'\n" "$option"
                printUsage
                exit 129
            ;;
        esac
    fi

    declare -r config_module_file="$PROZZIE_CLI_CONFIG/$module.bash"

    if [[ ! -f "$config_module_file" ]]; then
        printf "Unknow module: '%s'\n" "$module" >&2
        printf "Please use 'prozzie config --describe-all' to see a complete list of modules and their variables\n" >&2
        exit 1
    fi

    declare env_file="$PROZZIE_ENVS/$module.env"
    # If module is referred to base module then set $env_file to $base_env_file
    if [[ "$module" =~ ^base$ ]]; then
        env_file="$base_env_file"
    fi

    if [[ ! "$module" =~ ^(mqtt|syslog)$ && ! -f "$env_file" ]]; then
        printf "Module '%s' does not have a defined configuration (*.env file)\n" "$module">&2
        printf "You can set '%s' module configuration using --setup option.\n" "$module">&2
        printf "For more information see command help\n" >&2
        exit 1
    fi

    . "$config_module_file"

    case $# in
        0) # <module>
            if [[ "$module" =~ ^(mqtt|syslog)$ ]]; then
                  "${PREFIX}"/bin/prozzie kcli get "$module"
                exit 0
            fi
            zz_get_vars "$env_file"
            exit 0
        ;;
        1) # <module> <configuration-key>
            declare -r configuration_key="$1"
            shift
            if [[ "$module" =~ ^(mqtt|syslog)$ ]]; then
                "${PREFIX}"/bin/prozzie kcli get "$module"|grep -P "^${configuration_key}=.*$"|sed 's/'"${configuration_key}"'=//'
                exit 0
            fi
            zz_get_var "$env_file" "$configuration_key"
            exit 0
        ;;
        2) # <module> <configuration-key> <value-to-set>
            if [[ "$module" =~ ^(mqtt|syslog)$ ]]; then
                printf "Please use next commands in order to configure ${module}:\n" >&2
                printf "prozzie kcli rm <connector>\n" >&2
                printf "prozzie config -s ${module}\n" >&2
                exit 1
            fi
            zz_set_var "$env_file" "$@" || exit 1
        ;;
    esac
}

main "$@"