#!/usr/bin/env bash
# custom code to improve bash support for complex data types like maps and arrays globally
# depends on
# github.com/glaudiston/pragma_once
source $(dirname $(realpath $BASH_SOURCE))/pragma_once/bash/pragma_once.sh && return 0;
# --- State ---
SHM=/dev/shm/tui.$$
source $(dirname $(realpath $BASH_SOURCE))/arrays.sh
source $(dirname $(realpath $BASH_SOURCE))/maps.sh
datatypes_cleanup(){
	rm -f ${SHM}*
}

