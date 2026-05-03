
get_map_count(){
	declare -A v=$(get_map $1)
	echo ${#v[@]}
}
get_map() {
	touch $SHM.$1
	cat $SHM.$1
}
get_map_key(){
	declare -A v=$(get_map $1)
	declare -a keys=( ${!v[@]} )
	echo ${keys[$2]}
}
get_map_value(){
	declare -A v=$(get_map $1)
	[ "$2" == "" ] && return
	echo ${v[$2]:-}
}
lock(){
	while [ -e $1.lock ]; do sleep .1; done
	touch $1.lock
}
unlock(){
	[ -e $1.lock ] && rm $1.lock;
}
set_map_item(){
	lock $SHM.$1
	local items=$(get_array $1)
	[ "$items" == "" ] && {
		declare -A v=()
	} || declare -A v=$items
	v[$2]=$3
	declare -p v | cut -d= -f2- > $SHM.$1
	unlock $SHM.$1
}
