#!/usr/bin/bash
#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

UPDATE_ON_LAN=1
TIMEOUT=5
TMP_PASS_LEN=32

TEMPLATE_DIR=templates
ASSETS_DIR=assets

# EMAIL=
# DOMAIN=
# ID=
# CTHOSTNAME=
# WAN_IP=
# WAN_GATE=
# ROOTPASS=

DFL_EMAIL=user@example.com
DFL_DOMAIN=example.com
DFL_ID=100
DFL_CTHOSTNAME=ns
DFL_WAN_IP=192.168.1.101/24
DFL_WAN_GATE=192.168.1.252

TMP_PASS=$(cat /dev/urandom | base64 | head -c ${TMP_PASS_LEN:=32})


#----------------------------------------------------------------------

[ -z $EMAIL ] \
	&& read -ep "Email: " -i "$DFL_EMAIL" EMAIL
EMAIL=${EMAIL:=$DFL_EMAIL}
[ -z $DOMAIN ] \
	&& read -ep "Domain: " -i "$DFL_DOMAIN" DOMAIN
DOMAIN=${DOMAIN:=$DFL_DOMAIN}
[ -z $ID ] \
	&& read -ep "ID: " -i "$DFL_ID" ID
[ -z $CTHOSTNAME ] \
	&& read -ep "Hostname: " -i "$DFL_CTHOSTNAME" CTHOSTNAME
[ -z $WAN_IP ] \
	&& read -ep "WAN ip (stub): " -i "$DFL_WAN_IP" WAN_IP
[ -z $WAN_GATE ] \
	&& read -ep "WAN gateway (stub): " -i "$DFL_WAN_GATE" WAN_GATE
if [ -z $ROOTPASS ] ; then
	read -sep "root password (Enter to skip): " PASS1
	echo
	if [ $PASS1 ] ; then
		read -sep "retype root password: " PASS2
		echo
		if [[ $PASS1 != $PASS2 ]] ; then
			echo "ERR: passwords do not match."
			exit 1
		fi
		PASS=$PASS1
	fi
else
	PASS=$ROOTPASS
fi


#----------------------------------------------------------------------

echo Building config...
TEMPLATES=($(find "$TEMPLATE_DIR" -type f))
for file in "${TEMPLATES[@]}" ; do
	file=${file#${TEMPLATE_DIR}}
	echo Generating: ${file}...
	cat "${TEMPLATE_DIR}/${file}" \
		| sed \
			-e 's/\${EMAIL}/'$EMAIL'/' \
			-e 's/\${DOMAIN}/'$DOMAIN'/' \
			-e 's/\${CTHOSTNAME}/'$CTHOSTNAME'/' \
			-e 's/\${WAN_IP}/'${WAN_IP/\//\\/}'/' \
			-e 's/\${WAN_GATE}/'$WAN_GATE'/' \
		> "${ASSETS_DIR}/${file}"
done


#----------------------------------------------------------------------

echo Creating CT...

TEMPLATE=($(ls /var/lib/vz/template/cache/alpine-3.18*.tar.xz))

# XXX option to configure bridges...
# NOTE: we are not setting the password here to avoid printing it to the terminal...
@ pct create $ID \
	${TEMPLATE[-1]} \
	--hostname $CTHOSTNAME \
	--memory 128 \
	--swap 128 \
	--net0 name=lan,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
	--net1 name=admin,bridge=vmbr1,firewall=1,type=veth \
	--net2 name=wan,bridge=vmbr2,firewall=1${WAN_GATE:+,gw=${WAN_GATE}}${WAN_IP:+,ip=${WAN_IP}},type=veth \
	--storage local-lvm \
	--rootfs local-lvm:0.5 \
	--unprivileged 1 \
	--password="$TMP_PASS" \
	--start 1 \
|| exit 1

# XXX ifdown admin lan interfaces fro bootstrap...

echo Setting root password...
if [ $PASS ] ; then
	echo "root:$PASS" \
		| @ lxc-attach $ID chpasswd
fi

echo Updating container...
@ lxc-attach $ID apk update
@ lxc-attach $ID apk upgrade

echo Installing dependencies...
@ lxc-attach $ID apk add bash dnsmasq

echo Copying assets...
@ pct-push-r $ID ./assets /

echo Setup: dnsmasq...
@ lxc-attach $ID rc-update add dnsmasq
@ lxc-attach $ID rc-service dnsmasq start



echo Done.


#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :