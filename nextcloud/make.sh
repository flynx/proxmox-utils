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
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=nextcloud}

DFL_CORES=${DFL_CORES:=2}
DFL_RAM=${DFL_RAM:=2048}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=40}

# Nextcloud-specific configuration...
#APP_DOMAIN=nc.$DOMAIN
#DB_PASS=
#APP_PASS=
#SEC_ALERTS=SKIP

WAN_IP=-
WAN_GATE=-
ADMIN_IP=-
ADMIN_GATE=-
LAN_IP=-
LAN_GATE=-

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
getLatestTemplate '.*-turnkey-nextcloud' TEMPLATE
pctCreate $ID "$TEMPLATE" "$OPTS_STAGE_1" "$PASS"
sleep ${TIMEOUT:=5}

tklWaitForSetup

echo "# Starting TKL UI..."
# XXX might be a good idea to reaaad stuff from config...
@ lxc-attach $ID -- bash -c "\
	HUB_APIKEY=SKIP \
	SEC_UPDATES=SKIP \
	${APP_DOMAIN:+APP_DOMAIN=${APP_DOMAIN}} \
	${DB_PASS:+DB_PASS=${DB_PASS}} \
	${APP_PASS:+APP_PASS=${APP_PASS}} \
	${SEC_ALERTS:+SEC_ALERTS=${SEC_ALERTS}} \
		/usr/sbin/turnkey-init"

echo "# Updating config..."
# add gate IP to trusted_proxies...
@ lxc-attach $ID -- bash -c "\
	sed -i \
		-e \"/trusted_domains/i\\  'trusted_proxies' =>\\n  array (\\n    '${GATE_LAN_IP/\/*}\\/32',\\n  ),\" \
		/var/www/nextcloud/config/config.php"
# add self IP to trusted_domains -- enable setup from local network...
IP=$([ -z $DRY_RUN ] && lxc-attach $ID -- hostname -I)
@ lxc-attach $ID -- bash -c "\
	sed -z -i \
		-e \"s/\\(trusted_domains[^)]*\\)/\\1  2 => '${IP/ *}',\\n  /\" \
		/var/www/nextcloud/config/config.php"

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

echo "# Disabling fail2ban..."
# NOTE: we do not need this as we'll be running from behind a reverse proxy...
@ lxc-attach $ID systemctl stop fail2ban
@ lxc-attach $ID systemctl disable fail2ban

echo "# Updating system..."
@ lxc-attach $ID apt update 
@ lxc-attach $ID -- apt upgrade -y

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

saveLastRunConfig

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
