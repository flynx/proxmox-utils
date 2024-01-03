#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

[ -e ../config.global ] \
	&& source ../config.global

[ -e ./config ] \
	&& source ./config


#----------------------------------------------------------------------

DFL_ID=${DFL_ID:=101}
DFL_CTHOSTNAME=${GATE_HOSTNAME:=${DFL_CTHOSTNAME:=gate}}

DFL_WAN_IP=${DFL_WAN_IP}
DFL_WAN_GATE=${DFL_WAN_GATE}

DFL_ADMIN_IP=${GATE_ADMIN_IP:=${DFL_ADMIN_IP:=10.0.0.2/24}}
ADMIN_GATE=-
DFL_LAN_IP=${GATE_LAN_IP:=${DFL_LAN_IP:=10.1.1.2/24}}
LAN_GATE=-

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------

OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--memory 128 \
	--swap 128 \
	--net0 name=wan,bridge=vmbr${WAN_BRIDGE},firewall=1${WAN_GATE:+,gw=${WAN_GATE}}${WAN_IP:+,ip=${WAN_IP}},type=veth \
	--net1 name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1${ADMIN_IP:+,ip=${ADMIN_IP}},type=veth \
	--net2 name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1${LAN_IP:+,ip=${LAN_IP}},type=veth \
	--storage local-lvm \
	--rootfs local-lvm:0.5 \
	--unprivileged 1 \
	${PCT_EXTRA} \
"

OPTS_STAGE_2="\
	--startup order=80 \
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Building config..."
buildAssets "$TEMPLATE_DIR" "$ASSETS_DIR"

echo "# Creating CT..."
pctCreateAlpine $ID "${OPTS_STAGE_1}" "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID apk add bash bridge iptables traefik

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

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
@ lxc-attach $ID ln -s /root/routing.sh /etc/local.d/iptables-update.start

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
