#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${NS_ID:=${DFL_ID:-100}}
DFL_CTHOSTNAME=${NS_HOSTNAME:-${DFL_CTHOSTNAME:-ns}}

CORES=1
RAM=128
SWAP=$RAM
DRIVE=0.5

WAN_IP=SKIP
WAN_GATE=SKIP
# XXX revise...
DFL_ADMIN_IP=${DFL_ADMIN_IP:=10.0.0.1/24}
ADMIN_GATE=SKIP
# XXX revise...
DFL_LAN_IP=${NS_LAN_IP:=${DFL_LAN_IP:=10.1.1.1/24}}
# XXX revise...
DFL_LAN_GATE=${GATE_LAN_IP:=${DFL_LAN_GATE:=10.1.1.2}}
DFL_LAN_GATE=${DFL_LAN_GATE/\/*}

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------

INTERFACES=(
	"name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1${LAN_GATE:+,gw=$LAN_GATE}${LAN_IP:+,ip=$LAN_IP},type=veth"
	"name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1${ADMIN_IP:+,ip=$ADMIN_IP},type=veth"
)

OPTS_STAGE_2="\
	--startup order=90,up=10 \
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Building config..."
buildAssets

echo "# Creating CT..."
pctCreateAlpine $ID "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID apk add bash dnsmasq logrotate

echo "# Copying assets..."
pctPushAssets $ID

echo "# Setup: dnsmasq..."
@ lxc-attach $ID rc-update add dnsmasq
@ lxc-attach $ID rc-service dnsmasq start

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
