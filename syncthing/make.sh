#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${DFL_ID:=301}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=syncthing}

DFL_CORES=${DFL_CORES:=1}
DFL_RAM=${DFL_RAM:=1024}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=8}

WAN_IP=SKIP
WAN_GATE=SKIP
ADMIN_IP=SKIP
ADMIN_GATE=SKIP
LAN_IP=SKIP
LAN_GATE=SKIP

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------

INTERFACES=(
	"name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth"
	"name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1,ip=dhcp,type=veth"
)

OPTS_STAGE_2="\
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Building config..."
buildAssets

echo "# Creating CT..."
pctCreateAlpine $ID "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID apk add bash syncthing logrotate

echo "# Copying assets..."
pctPushAssets $ID

echo "# Setup: sysctl..."
@ lxc-attach $ID rc-update add sysctl

echo "# Setup: syncthing..."
@ lxc-attach $ID rc-update add syncthing
@ lxc-attach $ID rc-service syncthing start

echo "# Setup: dashboard..."
sleep ${TIMEOUT:=5}
@ lxc-attach $ID -- \
	sed \
		-e 's/tls="false"/tls="true"/g' \
		-e 's/127\.0\.0\.1:8384/0.0.0.0:443/g' \
		-i /var/lib/syncthing/.config/syncthing/config.xml

echo "# Setup: firewall..."
@ cp --backup -i fw/ID.fw /etc/pve/firewall/$ID.fw

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
