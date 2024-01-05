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

DFL_ID=${DFL_ID:=301}
DFL_CTHOSTNAME=${CTHOSTNAME:=${DFL_CTHOSTNAME:=syncthing}}

DFL_RAM=${RAM:=${DFL_RAM:=1024}}
DFL_SWAP=${SWAP:=${DFL_SWAP:=$RAM}}
DFL_DRIVE=${DRIVE:=${DFL_DRIVE:=8}}

WAN_IP=-
WAN_GATE=-
ADMIN_IP=-
ADMIN_GATE=-
LAN_IP=-
LAN_GATE=-

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------

OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--memory $RAM \
	--swap $SWAP \
	--net0 name=lan,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--net1 name=admin,bridge=vmbr1,firewall=1,ip=dhcp,type=veth \
	--storage local-lvm \
	--rootfs local-lvm:$DRIVE \
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
@ lxc-attach $ID apk add bash syncthing

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

echo "# Setup: dnsmasq..."
@ lxc-attach $ID rc-update add syncthing
@ lxc-attach $ID "sed \
		-e 's/127\.0\.0\.1:8384/0.0.0.0:8384/g' \
		-i /var/lib/syncthing/.config/syncthing/config.xml"
@ lxc-attach $ID rc-service syncthing start

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :

