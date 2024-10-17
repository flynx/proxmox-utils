#!/usr/bin/bash

# XXX should this be an interactive (env) option???
#PROXMOX_UTILS=git@github.com:flynx/proxmox-utils.git
PROXMOX_UTILS=${PROXMOX_UTILS:-https://github.com/flynx/proxmox-utils.git}

# XXX do we need to update the system here?
apt update
apt upgrade

# keep this to the minimum, at this point...
apt install \
	git make

git clone $PROXMOX_UTILS 

cd proxmox-utils

make bootstrap



# vim:set ts=4 sw=4 nowrap :
