#!/usr/bin/env bash

. common.sh

function cleanup {
	echo
	log warn "No changes made to $src_env_file"
	rm -rf "$tmp_env"
}

# [env_variable]="default|prompt"
declare -A module_envs=(
	[NETFLOW_PROBES]="|JSON object of NF probes (It's recommend to use env var) "
	[NETFLOW_COLLECTOR_PORT]='2055|In what port do you want to listen for netflow traffic? '
	[NETFLOW_KAFKA_TOPIC]='flow|Topic to produce netflow traffic? ')

function app_setup () {
	trap cleanup EXIT

	src_env_file="$DEFAULT_PREFIX/prozzie/.env"
	while [[ ! -f "$src_env_file" ]]; do
		read -p ".env file not found in \"$src_env_file\". Please provide .env path: " src_env_file
	done

	readonly tmp_env=$(mktemp)

	# Check if the user previously provided the variables. In that case,
	# offer user to mantain previous value.
	# TODO all the `$(declare -p module_envs)` are just a hack in order to
	# support old bash versions (<4.3, Centos 7 case), same with returning
	# and re-declaring it. With bash `4.3`. Proper way to do is to pass the
	# array variable, and use `local -n`.
	eval 'declare -A module_envs='$(zz_variables_env_update_array "$src_env_file" "$tmp_env" "$(declare -p module_envs)")
	zz_variables_ask "$tmp_env" "$(declare -p module_envs)"

	trap '' EXIT
	# Hurray! f2k installation end!
	cp "$tmp_env" "$src_env_file"
}

# Allow inclusion on other modules with no app_setup call
if [[ "$1" != "--source" ]]; then
	app_setup
fi
