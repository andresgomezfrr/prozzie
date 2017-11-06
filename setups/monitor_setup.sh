#!/usr/bin/env bash

. common.sh

monitor_custom_mib_prompt='monitor custom mibs path (use monitor_custom_mibs'
monitor_custom_mib_prompt="$monitor_custom_mib_prompt for no custom mibs)"

declare -A module_envs=(
	[MONITOR_REQUEST_TIMEOUT]='25|Seconds between monitor polling'
	[MONITOR_KAFKA_TOPIC]='monitor|Topic to produce monitor metrics'
	[MONITOR_CUSTOM_MIB_PATH]="monitor_custom_mibs|$monitor_custom_mib_prompt"
	[MONITOR_SENSORS_ARRAY]="''|Monitor agents array")

if [[ "$1" != '--source' ]]; then
	app_setup
fi
