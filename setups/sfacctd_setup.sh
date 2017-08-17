#!/usr/bin/env bash

. common.sh

declare -r sfacctd_aggregate='cos, etype, src_mac, dst_mac, vlan, src_host, \
	dst_host, src_mask, dst_mask, src_net, dst_net, proto, tos, src_port, \
	dst_port, tcpflags, src_as, dst_as, as_path, src_as_path,
	src_host_country, dst_host_country, in_iface, out_iface, sampling_rate, \
	export_proto_version, timestamp_arrival'

declare -A module_envs=(
	[SFLOW_KAFKA_TOPIC]="flow|Topic to produce netflow traffic"
	[SFLOW_COLLECTOR_PORT]="6343|In what port do you want to listen for sflow traffic"
	[SFLOW_RENORMALIZE]="true|Normalize sflow based on sampling"
	[SFLOW_AGGREGATE]="$sfacctd_aggregate|sfacctd aggregation fields")

if [[ "$1" != "--source" ]]; then
	app_setup
fi
