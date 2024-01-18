#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

webAppConfig Nextcloud

DFL_ID=${DFL_ID:=300}
DFL_CTHOSTNAME=${DFL_CTHOSTNAME:=nextcloud}

DFL_CORES=${DFL_CORES:=2}
DFL_RAM=${DFL_RAM:=2048}
DFL_SWAP=${DFL_SWAP:=${DFL_RAM}}
DFL_DRIVE=${DFL_DRIVE:=40}

# XXX do we request these???
GATE_LAN_IP=${GATE_LAN_IP:-${DFL_GATE_LAN_IP}}
GATE_HOSTNAME=${GATE_HOSTNAME:-${DFL_GATE_HOSTNAME}}
WAN_IP=${WAN_IP:-${DFL_WAN_IP}}

#WAN_IP=SKIP
WAN_GATE=SKIP
ADMIN_IP=SKIP
ADMIN_GATE=SKIP
LAN_IP=SKIP
LAN_GATE=SKIP

REBOOT=${REBOOT:=1}

readVars

# Nextcloud-specific configuration...
APP_DOMAIN=$DOMAIN
#DB_PASS=
#APP_PASS=
#SEC_ALERTS=SKIP


#----------------------------------------------------------------------

INTERFACES=(
	"name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth"
)

# XXX move this to .pct-helpers
INTERFACES_ARGS=()
i=0
for interface in "${INTERFACES[@]}" ; do
	INTERFACES_ARGS+=("--net${i} "${interface}"")
	i=$(( i + 1 ))
done
# NOTE: TKL gui will not function correctly without nesting enabled...
OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--cores $CORES \
	--memory $RAM \
	--swap $SWAP \
	"${INTERFACES_ARGS[@]}" \
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
pctCreateTurnkey 'nextcloud' $ID "$OPTS_STAGE_1" "$PASS"

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
		-e \"/trusted_domains/i\\  'trusted_proxies' =>\\n  array (\\n   0 => '${GATE_LAN_IP/\/*}\\/32',\\n  ),\" \
		/var/www/nextcloud/config/config.php"

# add self IP to trusted_domains -- enable setup from local network...
# XXX is the IP actually needed???
IP=$([ -z $DRY_RUN ] && lxc-attach $ID -- hostname -I)
# XXX the gate stuff might not be needed...
TRUSTED_DOMAINS=(
	"${IP/ *}"
	"$CTHOSTNAME"
	"${CTHOSTNAME}.srv"
	"${GATE_LAN_IP/\/*}"
	"${GATE_HOSTNAME}"
	"${GATE_HOSTNAME}.srv"
	"${WAN_IP/\/*}"
)
ADDRS=
i=2
for addr in "${TRUSTED_DOMAINS[@]}" ; do
	if [ -z "$addr" ] || [[ "$addr" == ".srv" ]] ; then
		continue
	fi
	ADDRS="${ADDRS}\ \ $i => '${addr//\//\\/}',\\n"
	i=$(( i + 1 ))
done
@ lxc-attach $ID -- bash -c "\
	sed -z -i \
		-e \"s/\\(trusted_domains[^)]*\\)/\\1${ADDRS}/\" \
		/var/www/nextcloud/config/config.php"

# remove /index.php from urls...
# for more info see:
#	https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html#pretty-urls
@ lxc-attach $ID -- bash -c "\
	sed -i \
		-e \"/trusted_proxies/i\\  'htaccess.RewriteBase' => '\\/',\\n\" \
		/var/www/nextcloud/config/config.php"
@ lxc-attach $ID -- turnkey-occ maintenance:update:htaccess

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
pctSetNotes $ID

saveLastRunConfig

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
