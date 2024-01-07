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
DFL_SWAP=${DFL_SWAP:=${DFL_RAM:=2048}}
DFL_DRIVE=${DFL_DRIVE:=40}

WAN_IP=-
WAN_GATE=-
ADMIN_IP=-
ADMIN_GATE=-
LAN_IP=-
LAN_GATE=-

REBOOT=${REBOOT:=1}

readVars


#----------------------------------------------------------------------

# XXX  cores...
OPTS_STAGE_1="\
	--hostname $CTHOSTNAME \
	--cores $CORES \
	--memory $RAM \
	--swap $SWAP \
	--net0 name=lan,bridge=vmbr${LAN_BRIDGE},firewall=1,ip=dhcp,type=veth \
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
getLatestTemplate '.*-turnkey-nextcloud' TEMPLATE
pctCreate $ID "$TEMPLATE" "$OPTS_STAGE_1" "$PASS"
sleep ${TIMEOUT:=5}

# hooking into tkl init process:
# 	- wait for /etc/inithooks.conf to be generated by:
# 		/usr/lib/inithooks/firstboot.d/29preseed
# 	  this file existion would mean that the first stage of setup is
# 	  done and we can do:
# 	  	lxc-attach $ID -- bash --login exit
# 	  to launch interactive setup...
# 	  XXX can we get console/log output while poling???
# 	- inject a script into the chain to do our stuff
# 	  Q: can we reuse tkl's scripts???
#
# 	* another strategy would be generate our own inithooks.conf but 
# 	  this would require us to mount the ct volume before first boot...
# 	  see:
# 	  	https://forum.proxmox.com/threads/pct-push-when-lxc-is-offline.116786/
# 	* might be usefull to do both to:
# 		- maximize compatibility / change tolerance (tkl ui) (???)
# 		- skip dialogs we do not use...
# 		  ...i.e. poll-patch-ui
#
# for tkl inithooks doc see:
# 	https://www.turnkeylinux.org/docs/inithooks

printf "# TKL setup, this may take a while"
while ! $(lxc-attach $ID -- test -e /etc/inithooks.conf) ; do
	printf '.'
	sleep 5
done
printf '+'
while ! [[ $(lxc-attach $ID -- cat /etc/inithooks.conf | wc -c) < 2 ]] ; do
	printf '.'
	sleep 5
done
printf 'ready.\n'
sleep 5

echo "# Starting TKL UI..."
@ lxc-attach $ID -- bash --login -c 'exit'

exit

# XXX the CT will reboot -- wait...

##@ lxc-attach $ID -- /usr/sbin/trunkey-init
#
#echo "# Updating config..."
## XXX update /var/www/nextcloud/config/config.php
##	- trusted_domains
##	- trusted_proxies
#@ lxc-attach $ID -- \
#	sed \
#		-e 's/^\(\s*\)\('\''trusted_domains\)/\1'\''trusted_proxies'\'' =>\n\1array (\n\1\1'${GATE_LAN_IP}'\/32\n\1)\n\1\2/' \
#		-i /var/www/nextcloud/config/config.php

echo "# Copying assets..."
@ pct-push-r $ID ./assets /

echo "# Disabling fail2ban..."
# NOTE: we do not need this as we'll be running from behind a reverse proxy...
@ lxc-attach $ID systemctl stop fail2ban
@ lxc-attach $ID systemctl disable fail2ban

echo "# Post config..."
pctSet $ID "${OPTS_STAGE_2}" $REBOOT

echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :


