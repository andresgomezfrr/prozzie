#!/usr/bin/env bash

. common.sh

function cleanup {
	echo
	log warn "No changes made to $env_file"
	rm -rf "$tmp_env"
}
trap cleanup EXIT

# [env_variable]="default|prompt"
declare -A f2k_envs=(
	[NETFLOW_PROBES]="|JSON object of NF probes (It's recommend to use env var) "
	[NETFLOW_COLLECTOR_PORT]='2055|In what port do you want to listen for netflow traffic? '
	[NETFLOW_KAFKA_TOPIC]='flow|Topic to produce netflow traffic? ')

# Ask user for variable value.
# Parameters:
#  $1 variable key in f2k_envs
#  $2 (optional) Variable default value. If $1 is not an f2k variable, and $2
#                argument is not provided, $1 variable will be set to "" in env
#                file!
#  Note: As in zz_variable, user will not be asked if environment variable $1 is
#  already defined
function read_f2k_variable {
	local readonly var_key="$1"
	if [ ${f2k_envs[$var_key]+_} ]; then
		# f2k variable
		IFS='|' read var_default var_prompt <<< "${f2k_envs[$var_key]}"

		if [ $# -gt 1 ]; then
			var_default="$2"
		fi
	else
		# Not f2k variable, zz_variable will just copy it. This path NEEDS $2
		declare "$var_key=$2"
	fi

	local readonly prompt=$(printf "%s [%s]:" "$var_prompt" "$var_default")
	zz_variable --env-file="$tmp_env" "$var_key" "$var_default" "$prompt"
	unset f2k_envs["$var_key"]
}

env_file="$PREFIX/prozzie/.env"
while [[ ! -f "$env_file" ]]; do
	read -p ".env file not found in \"$env_file\". Please provide .env path: " env_file
done

readonly tmp_env=$(mktemp)

# Check if the user previously provided the variables. In that case, offer user
# to mantain previous value.
while IFS='=' read -r var_key var_val || [[ -n "$var_key" ]]; do
	read_f2k_variable "$var_key" "$var_val" < /dev/tty
done < "$env_file"

# Loop over variables that were not set in provided .env
for f2k_env_key in "${!f2k_envs[@]}"; do
	read_f2k_variable "$f2k_env_key"
done

# Hurray! f2k installation end!
cp "$tmp_env" "$env_file"
