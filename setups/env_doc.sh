#!/usr/bin/env bash

declare -r SETUP_FILE_SUFFIX='_setup.sh'

function print_table_header () {
	echo '<table><tr><th>ENV</th><th>Default</th><th>Description</th></tr>'
}

function print_table_footer () {
	echo '</table>'
}

# Print zz variable environments of a setup file
# Arguments:
#  File path
function print_envs () {
	. "$1" --source

	local -r MODULE_NAME=${1%_setup.sh}

	echo "<tr><th colspan=\"3\" align=\"center\">$MODULE_NAME</th></tr>"

	for env in "${!module_envs[@]}"; do
		IFS='|' read env_default env_description <<< "${module_envs[$env]}"
		if [[ -z "$env_default" ]]; then
			env_default='(No default)'
		fi
		printf '<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n' "$env" "$env_default" "$env_description"
	done
}

print_table_header

for setup_script in *$SETUP_FILE_SUFFIX; do
	(print_envs "$setup_script")
done

print_table_footer
