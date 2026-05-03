#!/usr/bin/env bash
# depends on
# github.com/glaudiston/pragma_once
source $(dirname $(realpath $BASH_SOURCE))/pragma_once/bash/pragma_once.sh || return 0;
get_array() {
	touch $SHM.$1
	cat $SHM.$1
}
get_array_count(){
	declare -a v=$(get_array $1)
	echo ${#v[@]}
}
get_array_item(){
	declare -a v=$(get_array "$1")
	echo ${v[$2]}
}
set_array_item(){
	lock $SHM.$1
	local items=$(get_array $1)
	[ "$items" == "" ] && {
		declare -a v=()
	} || declare -a v=$items
	local p=${#v[@]};
	v[p]=$2
	declare -p v | cut -d= -f2- > $SHM.$1
	unlock $SHM.$1
}

