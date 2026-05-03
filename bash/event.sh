#!/usr/bin/env bash
# Topic Event Manager
# This is a publish/subscribe event manager implementation
# So we can implement event driven code with bash.
#
# Depends on:
# github.com/glaudiston/pragma_once
source $(dirname $(realpath $BASH_SOURCE))/pragma_once/bash/pragma_once.sh && return 0;
source $(dirname $(realpath $BASH_SOURCE))/data_types.sh
APP_NAME=${BASH_SOURCE[-1]}
DATA_PATH=${XDG_DATA_HOME:-$HOME/.local/share}/${APP_NAME}/events
mkdir -p "$DATA_PATH";
EVENT_STORE="session_data.jsonl"
publish() {
	local topic=$1;
	local task=$2;
	local status="";
	local msg="";
	local ts=$(date +%s%N)
	local topicEventStore="$DATA_PATH/${topic}.${EVENT_STORE}"
	touch "$topicEventStore"
	[ $# -gt 2 ] && status=$3;
	[ $# -gt 3 ] && msg=$4;
	(
		flock -x 200
		for (( i=0; i<$(get_array_count $topic); i++ ));
		do 
			local sub=$(get_array_item $topic $i);
			if [[ -n "$sub" ]]; then
				"$sub" "$topic" "$task" "$status" "$msg" "$ts" &
			fi
		done;
		local topicLastHash="$(tail -1 "${topicEventStore}"|grep -oP '"hash":"\K[^"]+')";
		local hash_data="${topicLastHash}${ts}${topic}${task}${status}${msg}";
		local hash=$(md5sum<<<"$hash_data"|cut -d\  -f1)
		jq -n \
			--arg h "$hash" \
			--arg ts "$ts" \
			--arg top "$topic" \
			--arg task "$task" \
			--arg stat "$status" \
			--arg msg "$msg" \
			'{hash: $h, ts: $ts, topic: $top, task: $task, status: $stat, msg: $msg}' \
		>> "${topicEventStore}"
	) 200>"${topicEventStore}.lock"
}

subscribe() {
	set_array_item $1 $2
}
