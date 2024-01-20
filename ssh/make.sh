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

INTERFACES=(
	"name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth"
	"name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1,ip=dhcp,type=veth"
	"name=wan,bridge=vmbr${WAN_BRIDGE},firewall=1${WAN_SSH_IP:+,ip=${WAN_SSH_IP}},type=veth"
)

OPTS_STAGE_2="\
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Building config..."
buildAssets WAN_SSH_IP

echo "# Creating CT..."
pctCreateDebian $ID "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID -- bash -c 'yes | apt install vim htop iftop iotop tmux mc sudo'

echo "# Copying assets..."
pctPushAssets $ID

echo "# Setup: users..."
while true ; do
	xread "User name for ssh (empty to skip): " SSH_USER
	if [ -z "$SSH_USER" ] ; then
		break
	fi

	@ lxc-attach $ID -- adduser $SSH_USER

	if xreadYes "Add another user?" ; then
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


