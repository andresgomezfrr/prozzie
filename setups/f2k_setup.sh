#!/usr/bin/env bash

. common.sh

declare -A module_envs=(
	[NETFLOW_PROBES]="|JSON object of NF probes (It's recommend to use env var) "
	[NETFLOW_COLLECTOR_PORT]='2055|In what port do you want to listen for netflow traffic? '
	[NETFLOW_KAFKA_TOPIC]='flow|Topic to produce netflow traffic? ')

if [[ "$1" != "--source" ]]; then
	app_setup
fi
