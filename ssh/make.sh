#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${DFL_ID:=102}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=ssh}

DFL_CORES=${DFL_CORES:=1}
DFL_RAM=${DFL_RAM:=1024}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=16}

WAN_IP=SKIP
WAN_GATE=SKIP
ADMIN_IP=SKIP
ADMIN_GATE=SKIP
LAN_IP=SKIP
LAN_GATE=SKIP

REBOOT=${REBOOT:=1}

DFL_WAN_SSH_IP=${DFL_WAN_SSH_IP:=}
xread "WAN ssh ip:" WAN_SSH_IP

readVars



#----------------------------------------------------------------------

OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--cores $CORES \
	--memory $RAM \
	--swap $SWAP \
	--net0 name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth \
	--net1 name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1,ip=dhcp,type=veth \
	--net2 name=wan,bridge=vmbr${WAN_BRIDGE},firewall=1${WAN_SSH_IP:+,ip=${WAN_SSH_IP}},type=veth \
	--storage local-lvm \
	--rootfs local-lvm:$DRIVE \
	--unprivileged 1 \
	--features nesting=1 \
	${PCT_EXTRA} \
"

OPTS_STAGE_2="\
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Creating CT..."
pctCreateDebian $ID "${OPTS_STAGE_1}" "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID -- bash -c 'yes | apt install vim htop iftop iotop tmux mc sudo'

echo "# Setup: users..."
while true ; do
	xread "user name for ssh: " SSH_USER
	[ -z $SSH_USER ] \
		|| @ lxc-attach $ID -- adduser $SSH_USER
	read -ep "Add another user? [y/N] " MORE
	if [[ $MORE == 'y' ]] ; then
		continue
	fi
	break
done

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :


