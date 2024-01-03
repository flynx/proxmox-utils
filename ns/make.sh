#!/usr/bin/bash
#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

[ -e ../config.global ] \
	&& source ../config.global

[ -e ./config ] \
	&& source ./config


#----------------------------------------------------------------------

DFL_ID=100
DFL_CTHOSTNAME=ns

WAN_IP=-
WAN_GATE=-
DFL_ADMIN_IP=${DFL_ADMIN_IP:=10.0.0.1/24}
ADMIN_GATE=-
DFL_LAN_IP=${DFL_LAN_IP:=10.1.1.1/24}
DFL_LAN_GATE=${DFL_LAN_IP:=10.1.1.2/24}

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------

OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--memory 128 \
	--swap 128 \
	--net0 name=lan,bridge=vmbr0,firewall=1${LAN_GATE:+,gw=$LAN_GATE}${LAN_IP:+,ip=$LAN_IP},type=veth \
	--net1 name=admin,bridge=vmbr1,firewall=1${ADMIN_IP:+,ip=$ADMIN_IP},type=veth \
	--storage local-lvm \
	--rootfs local-lvm:0.5 \
	--unprivileged 1 \
	${PCT_EXTRA} \
"

OPTS_STAGE_2="\
	--startup order=90,up=10 \
	--onboot 1 \
"


#----------------------------------------------------------------------

echo "# Building config..."
buildAssets "$TEMPLATE_DIR" "$ASSETS_DIR"

echo "# Creating CT..."
pctCreateAlpine $ID "${OPTS_STAGE_1}" "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID apk add bash dnsmasq

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

echo "# Setup: dnsmasq..."
@ lxc-attach $ID rc-update add dnsmasq
@ lxc-attach $ID rc-service dnsmasq start

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

echo "# Done."


#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
