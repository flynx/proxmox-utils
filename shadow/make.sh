#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

DFL_ID=${DFL_ID:=1010}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=shadow}

DFL_CORES=${DFL_CORES:=1}
DFL_RAM=${DFL_RAM:=256}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=0.5}

# XXX this is not used yet -- need to set this at traefik endpoint... 
#DFL_ENDPOINT_PORT=${DFL_ENDPOINT_PORT:=5555}
#xread "Shadowsocks endpoint port: " ENDPOINT_PORT

WAN_IP=SKIP
WAN_GATE=SKIP
ADMIN_IP=SKIP
ADMIN_GATE=SKIP
LAN_IP=SKIP
LAN_GATE=SKIP

REBOOT=${REBOOT:=1}

readVars


USER=shadowsocks


#----------------------------------------------------------------------

INTERFACES=(
	"name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth"
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
@ lxc-attach $ID -- \
	sed \
		-e '/v3\.\d*/{p;s|v3\.\d*|edge|}' \
		-i /etc/apk/repositories
@ lxc-attach $ID apk add bash libqrencode logrotate shadowsocks-rust


echo "# Copying assets..."
pctPushAssets $ID


echo "# Generating/updating config and server script..."
@ lxc-attach $ID bash /root/update-shadowsocks.sh


echo "# Profile: $*"

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT
pctSetNotes $ID

saveLastRunConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
