#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${GATE_ID:=${DFL_ID:-102}}
DFL_CTHOSTNAME=${GATE_HOSTNAME:-${DFL_CTHOSTNAME:-gate}}

CORES=1
RAM=128
SWAP=$RAM
DRIVE=0.5

DFL_WAN_IP=${DFL_WAN_IP}
DFL_WAN_GATE=${DFL_WAN_GATE}

# XXX revise...
DFL_ADMIN_IP=${GATE_ADMIN_IP:=${DFL_ADMIN_IP:=10.0.0.2/24}}
ADMIN_GATE=SKIP
# XXX revise...
DFL_LAN_IP=${GATE_LAN_IP:=${DFL_LAN_IP:=10.1.1.2/24}}
LAN_GATE=SKIP

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------
# Bootstrap...

if ! [ -z $BOOTSTRAP ] ; then
	WAN_BRIDGE=$ADMIN_BRIDGE
else
	# XXX
	true
fi



#----------------------------------------------------------------------


# XXX add interface bootstrap...
INTERFACES=(
	"name=wan,bridge=vmbr${WAN_BRIDGE},firewall=1${WAN_GATE:+,gw=${WAN_GATE}}${WAN_IP:+,ip=${WAN_IP}},type=veth"
	"name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1${ADMIN_IP:+,ip=${ADMIN_IP}},type=veth"
	"name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1${LAN_IP:+,ip=${LAN_IP}},type=veth"
)

OPTS_STAGE_2="\
	--startup order=80 \
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Building config..."
buildAssets

echo "# Creating CT..."
pctCreateAlpine $ID "$PASS"

# XXX this requires a bootsrapped interface...
echo "# Installing dependencies..."
@ lxc-attach $ID apk add bash bridge iptables traefik logrotate

echo "# Copying assets..."
pctPushAssets $ID

echo "# Setup: traefik..."
@ lxc-attach $ID rc-update add traefik
@ lxc-attach $ID rc-service traefik start

echo "# Setup: iptables..."
@ lxc-attach $ID rc-update add iptables
@ lxc-attach $ID bash /root/routing.sh
@ lxc-attach $ID rc-service iptables save
@ lxc-attach $ID rc-service iptables start

echo "# Setup: iptables update script..."
@ lxc-attach $ID rc-update add local
@ lxc-attach $ID -- ln -s /root/routing.sh /etc/local.d/iptables-update.start

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
