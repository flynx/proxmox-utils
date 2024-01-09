#!/usr/bin/bash
#----------------------------------------------------------------------
# https://wiki.alpinelinux.org/wiki/Configure_a_Wireguard_interface_(wg)

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${DFL_ID:=103}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=wireguard}

DFL_CORES=${DFL_CORES:=1}
DFL_RAM=${DFL_RAM:=256}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=1}

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
	--cores $CORES \
	--memory $RAM \
	--swap $SWAP \
	--net0 name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth \
	--net1 name=admin,bridge=vmbr${ADMIN_BRIDGE},firewall=1,ip=dhcp,type=veth \
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

echo "# Building config..."
buildAssets "$TEMPLATE_DIR" "$ASSETS_DIR"

echo "# Creating CT..."
pctCreateAlpine $ID "${OPTS_STAGE_1}" "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID apk add iptables wireguard-tools-wg-quick

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

#echo "# Setup: wireguard server..."
#@ lxc-attach $ID -- bash -c 'wg genkey | tee server.privatekey | wg pubkey > server.publickey' 

# XXX move this into a script on the CT side...
echo "# Setup: wireguard user..."
xread "profile name: " WG_PROFILE
xread "allowed ips: " ALLOWED_IPs

# XXX client:
# 	- generate keys
# 	- add to wg0.conf
# 	- add to $WG_PROFILE.conf

echo "# Setup: bridge device..."
@ lxc-attach $ID wg up wg0 

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :


