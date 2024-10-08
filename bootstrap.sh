#!/usr/bin/bash

# XXX run self in nohup
# 		..."$ make host" will likely break existing connections...
# XXX TEST!

# bootstrap...
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

#@ git clone git@github.com:flynx/proxmox-utils.git
@ git clone https://github.com/flynx/proxmox-utils.git

@ cd proxmox-utils

source ./.pct-helpers


# XXX create bootstrap gate...
# XXX


# vim:set ts=4 sw=4 nowrap :
