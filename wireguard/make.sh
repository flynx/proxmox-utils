#!/usr/bin/bash
#----------------------------------------------------------------------
# https://wiki.alpinelinux.org/wiki/Configure_a_Wireguard_interface_(wg)

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

# check dependencies...
would-like dig #qrencode


#----------------------------------------------------------------------

readConfig

DFL_ID=${DFL_ID:=130}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=wireguard}

DFL_CORES=${DFL_CORES:=1}
DFL_RAM=${DFL_RAM:=256}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=1}

WAN_IP=SKIP
WAN_GATE=SKIP
ADMIN_IP=SKIP
ADMIN_GATE=SKIP
LAN_IP=SKIP
LAN_GATE=SKIP

REBOOT=${REBOOT:=1}


# Wireguard config...
DFL_ENDPOINT=${DFL_ENDPOINT:=$(\
	which dig > /dev/null 2>&1 \
		&& (dig +short ${DOMAIN:-$DFL_DOMAIN} \
			| tail -1) \
		|| echo "${DOMAIN:-$DFL_DOMAIN}")}
xread "Wireguard endpoint: " ENDPOINT

DFL_ENDPOINT_PORT=${DFL_ENDPOINT_PORT:=51820}
xread "Wireguard endpoint port: " ENDPOINT_PORT

CLIENT_IPS=${CLIENT_IPS:-10.42.0.0/16}
ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0,${CLIENT_IPS}}

DNS=${DNS:-${NS_LAN_IP:-${DFL_NS_LAN_IP}}}
DNS=${DNS/\/*}
xread "Local network DNS:" DNS

xreadYes "Show profile as QRcode when done?" QRCODE
QRCODE=${QRCODE:-0}


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
buildAssets ENDPOINT ENDPOINT_PORT DNS CLIENT_IPS ALLOWED_IPS

echo "# Creating CT..."
pctCreateAlpine $ID "$PASS"

echo "# Installing dependencies..."
@ lxc-attach $ID apk add \
	iptables wireguard-tools-wg-quick make bind-tools libqrencode-tools logrotate

echo "# Copying assets..."
pctPushAssets $ID
@ lxc-attach $ID -- chmod +x /root/getFreeClientIP

echo "# Setup: wireguard server and client profile..."
@ lxc-attach $ID -- bash -c "cd /root \
	&& QRCODE=${QRCODE} make server default.client" 

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

echo "# Traefik config..."
traefikPushConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
