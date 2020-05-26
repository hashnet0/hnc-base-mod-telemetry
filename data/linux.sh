#!/bin/bash
# Copyright (c) 2020 HashNet Services

API_KEY=""
CONTAINER_NAME=""

if [ ! -z "$API_KEY" ]; then
	echo -e "WARNING: API_KEY was set, overriding environment variable."
	HASHNET_API_KEY=$API_KEY
fi

if [ ! -z "$CONTAINER_NAME" ]; then
	echo -e "WARNING: CONTAINER_NAME was set, overriding environment variable."
	HNC_NAME=$CONTAINER_NAME
fi

if [ "$EUID" -ne 0 ]; then
	echo -e "$(tput bold)$(tput setaf 1)HashNet Telemetry must be run as root!$(tput sgr0)"
	exit
fi

function klog {
	echo -e "$1"
	echo -e "hashnet-telemetry: $1" | tee /dev/kmsg 2>&1 >/dev/null
}

klog "Sending telemetry beacon ..."
response=$(/usr/bin/curl -s -X POST -H "Api-Key: ${HASHNET_API_KEY}" \
	-d container_name=${HNC_NAME} \
	-d kernel=$(uname -s) \
	-d hostname=$(uname -n) \
	-d architecture=$(uname -m) \
	-d os=$(uname -o) \
	-d os_release=$(uname -r) \
	-d os_version=$(uname -v) \
	-d cpu_count=$(nproc --all) \
	-d cpu_history_avg=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}') \
	-d cpu_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat)) \
	-d mem_total=$(free -m | grep Mem | awk '{print $2}') \
	-d mem_used=$(free -m | grep Mem | awk '{print $3}') \
	-d mem_free=$(free -m | grep Mem | awk '{print $4}') \
	-d mem_shared=$(free -m | grep Mem | awk '{print $5}') \
	-d mem_buffer_cache=$(free -m | grep Mem | awk '{print $6}') \
	-d mem_available=$(free -m | grep Mem | awk '{print $7}') \
	-d storage_size=$(du -Ps / 2>/dev/null | awk '{print $1}') \
	-d uptime=$(awk '{print $1}' /proc/uptime) \
	"https://api.hashsploit.net/telemetry/v1/hnc")

status=$(echo -en $response | jq .status.success)

if [ $status = "true" ]; then
	klog "Successfully sent telemetry beacon."
else
	error=$(echo -en $response | jq .status.error)
	klog "Error while sending beacon. Response: $error"
fi
