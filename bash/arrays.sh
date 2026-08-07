#!/usr/bin/env bash

get_array() {
	touch "$SHM.$1";
	cat "$SHM.$1";
}

get_array_count(){
	declare -a v=$(get_array $1)
	echo ${#v[@]}
}

get_array_item(){
	declare -a v=$(get_array "$1");
	echo "${v[$2]}";
}

set_array_item(){
	lock "$SHM.$1"
	local items=$(get_array "$1")
	if [ "$items" == "" ]; then {
		declare -a v=();
	} else
		declare -a v=$items;
	fi;
	local p=${#v[@]};
	v[p]=$2
	declare -p v | cut -d= -f2- > "$SHM.$1"
	unlock "$SHM.$1"
}

remove_array_item(){
	lock "$SHM.$1"
	local items=$(get_array "$1")
	if [ "$items" == "" ]; then {
		declare -a v=();
	} else
		declare -a v=$items;
	fi;
	local i;
	for (( i=0; i<${#v[@]}; i++ ));
	do
		[[ "${v[i]}" == "$2" ]] && unset 'v[i]';
	done;
	v=("${v[@]}");
	declare -p v | cut -d= -f2- > "$SHM.$1"
	unlock "$SHM.$1"
}
