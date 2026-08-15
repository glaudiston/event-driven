#!/usr/bin/env bash
# Generic Topic Event Manager
# This is a publish/subscribe event manager implementation
# So we can implement event driven code with bash.
#
# Depends on:
# github.com/glaudiston/pragma_once
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/pragma_once/bash/import_bash.sh";
import_bash ./data_types.sh
APP_NAME=${BASH_SOURCE[-1]}
HOME=${HOME:-/home/$(whoami)}
DATA_PATH=${XDG_DATA_HOME:-$HOME/.local/share}/${APP_NAME}/events
mkdir -p "$DATA_PATH";
EVENT_STORE="session_data.jsonl"
publish() {
	local topic=$1;
	shift # to remove the topic from the argument list
	local payload="$*";
	local ts;
	ts=$(date +%s%N)
	local topicEventStore="$DATA_PATH/${topic}.${EVENT_STORE}"
	touch "$topicEventStore"
	(
		local topicLastHash="$(tail -1 "${topicEventStore}"|grep -o '"hash":"[^"]+.')";
		local hash_data="${topicLastHash}${ts}${topic}${payload}";
		local hash;
		hash=$(md5sum<<<"$hash_data"|cut -d\  -f1)
		flock -x 200
		for (( i=0; i<$(get_array_count "$topic"); i++ ));
		do 
			local sub;
			sub=$(get_array_item "$topic" "$i");
			if [[ -n "$sub" ]]; then
				"$sub" "$topic" "$hash" "$ts" "$payload" &
			fi
		done;
		jq -n \
			--arg top "$topic" \
			--arg h "$hash" \
			--arg ts "$ts" \
			--arg payload "$payload" \
			'{topic: $top, hash: $h, ts: $ts, payload: $payload}' \
		>> "${topicEventStore}"
	) 200>"${topicEventStore}.lock"
}

subscribe() {
	local i;
	local c;
	c="$(get_array_count "$1")";
	for (( i=0; i<c; i++ )); do
		[[ "$(get_array_item "$1" "$i")" == "$2" ]] && return; # only subscribe if not already subscribed
	done;
	set_array_item "$1" "$2"
}

unsubscribe() {
	remove_array_item "$1" "$2"
}
