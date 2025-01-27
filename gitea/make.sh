#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

webAppConfig gitea

DFL_ID=${DFL_ID:=300}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=gitea}

DFL_CORES=${DFL_CORES:=2}
DFL_RAM=${DFL_RAM:=1024}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=40}

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
)

OPTS_STAGE_2="\
	--onboot 1 \
"


#----------------------------------------------------------------------
# XXX do a version using alpune...
# 		see:
# 			https://wiki.alpinelinux.org/wiki/Gitea
#

echo "# Building config..."
buildAssets

echo "# Creating CT..."
pctCreateTurnkey 'gitea' $ID "$PASS"

echo "# Starting TKL UI..."
@ lxc-attach $ID -- bash -c "HUB_APIKEY=SKIP SEC_UPDATES=SKIP /usr/sbin/turnkey-init"

echo "# Copying assets..."
pctPushAssets $ID

echo "# Disabling fail2ban..."
# NOTE: we do not need this as we'll be running from behind a reverse proxy...
@ lxc-attach $ID systemctl stop fail2ban
@ lxc-attach $ID systemctl disable fail2ban

echo "# Updating system..."
pctUpdateTurnkey $ID

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
