#!/usr/bin/env bash
# custom code to improve bash support for complex data types like maps and arrays globally
# depends on
# github.com/glaudiston/pragma_once
source "$(dirname "$(realpath $BASH_SOURCE)")/pragma_once/bash/import_bash.sh";
import_bash ./arrays.sh;
import_bash ./maps.sh;
# --- State ---
SHM=/dev/shm/tui.$$
datatypes_cleanup(){
	rm -f ${SHM}*
}

