#!/usr/bin/env bash
# custom code to improve bash support for complex data types like maps and arrays globally
# depends on
# github.com/glaudiston/pragma_once
source "$(dirname "$(realpath $BASH_SOURCE)")/pragma_once/bash/import_bash.sh";
import_bash ./arrays.sh;
import_bash ./maps.sh;
# --- State ---
[[ -d /dev/shm ]] && SHM_DIR=/dev/shm || SHM_DIR=/tmp
SHM=$SHM_DIR/tui.$$
datatypes_cleanup(){
	rm -f ${SHM}*
}

