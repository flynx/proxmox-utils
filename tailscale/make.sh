#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${DFL_ID:=1020}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=tailscale}

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

xread "Tailscale Auth Key: " TAILSCALE_AUTH_KEY

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

echo "# Enabling TUN for CT..."
# XXX can we do this with pct set ... ???
cat >> $CT_DIR/$ID <<EOF
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF
pct reboot $ID

echo "# Installing dependencies..."
@ lxc-attach $ID apk add tailscale logrotate

echo "# Copying assets..."
pctPushAssets $ID

echo "# Setup: sysctl..."
@ lxc-attach $ID rc-update add sysctl

echo "# Setup: tailscale..."
@ lxc-attach $ID rc-update add tailscale
@ lxc-attach $ID rc-service tailscale start
if ! [ -z $TAILSCALE_AUTH_KEY ] ; then
	@ lxc-attach $ID tailscale up --auth-key="$TAILSCALE_AUTH_KEY" --advertise-exit-node
fi

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
