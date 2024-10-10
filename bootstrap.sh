#!/usr/bin/bash

# XXX should this be an interactive (env) option???
#PROXMOX_UTILS=git@github.com:flynx/proxmox-utils.git
PROXMOX_UTILS=${PROXMOX_UTILS:-https://github.com/flynx/proxmox-utils.git}



# XXX run self in nohup
# 		..."$ make host" will likely break existing connections...
# XXX TEST!

# bootstrap...
# XXX might be a better idea to bootstrap the bootstrap by dowloading
# 		the .pct-helpers...
#QUIET=
#DRY_RUN=
ECHO_PREFIX="### "
function @ (){
	if [ -z $DRY_RUN ] ; then
		! [ $QUIET ] \
			&& echo -e "${ECHO_PREFIX}$@"
		"$@"
	else
		echo -e $@
	fi
	return $?
}

# XXX test if running as root...
# XXX

@ apt update
@ apt upgrade

# XXX
@ apt install \
	git make wget

@ git clone $PROXMOX_UTILS 

@ cd proxmox-utils

source ./.pct-helpers


# XXX create bootstrap gate...
# XXX


# vim:set ts=4 sw=4 nowrap :
