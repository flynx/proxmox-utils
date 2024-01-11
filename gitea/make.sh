#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

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

# NOTE: TKL gui will not function correctly without nesting enabled...
OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--cores $CORES \
	--memory $RAM \
	--swap $SWAP \
	--net0 name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth \
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
buildAssets

echo "# Creating CT..."
pctCreateTurnkey 'gitea' $ID "$OPTS_STAGE_1" "$PASS"

echo "# Starting TKL UI..."
@ lxc-attach $ID -- bash -c "HUB_APIKEY=SKIP SEC_UPDATES=SKIP /usr/sbin/turnkey-init"

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

echo "# Disabling fail2ban..."
# NOTE: we do not need this as we'll be running from behind a reverse proxy...
@ lxc-attach $ID systemctl stop fail2ban
@ lxc-attach $ID systemctl disable fail2ban

echo "# Updating system..."
pctUpdateTurnkey $ID

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

saveLastRunConfig

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
