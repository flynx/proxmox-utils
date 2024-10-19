#!/usr/bin/bash

# XXX should this be an interactive (env) option???
#PROXMOX_UTILS=git@github.com:flynx/proxmox-utils.git
PROXMOX_UTILS=${PROXMOX_UTILS:-https://github.com/flynx/proxmox-utils.git}

# keep this to the minimum, at this point...
apt install \
	git make wget

git clone $PROXMOX_UTILS 

cd proxmox-utils

make bootstrap



# vim:set ts=4 sw=4 nowrap :
