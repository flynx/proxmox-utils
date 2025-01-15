#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------
# CLI...

usage(){
	echo "$0 FROM TO"
}

if [ $# != 2 ] ; then
	usage
	echo "Not enough arguments."
	exit 1
fi

# XXX should we get FROm from config???
FROM=$1
TO=$2


# XXX should we build TO if it's not there???



#----------------------------------------------------------------------

@ lxc-attach $FROM -- turnkey-occ maintenance:mode --on
@ lxc-attach $TO -- turnkey-occ maintenance:mode --on

# XXX should we sleep here for a minute or 6 as is recommended in the docs???

# sql
@ lxc-attach $TO -- mysql -e "DROP DATABASE nextcloud"
@ lxc-attach $TO -- mysql -e "CREATE DATABASE nextcloud"
@@ "lxc-attach $FROM -- mysqldump --single-transaction nextcloud \
	| lxc-attach $TO -- mysql nextcloud"

# instance id's...
FROM_INSTANCEID=$(lxc-attach $FROM -- turnkey-occ config:system:get instanceid)
TO_INSTANCEID=$(lxc-attach $TO -- turnkey-occ config:system:get instanceid)


# files...
@ pct mount $FROM
@ pct mount $TO

# mirgate files and data...
@ rsync -Aavx \
	/var/lib/lxc/$FROM/rootfs/var/www/nextcloud-data/ \
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data
# migrate theming and other instance files...
APPDATA=/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$TO_INSTANCEID
[ -e "$APPDATA" ] \
	&& mv -f "$APPDATA" "${APPDATA}.bak"
@ mv -f \
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$FROM_INSTANCEID \
	"$APPDATA"
### XXX should we copy the whole thing???
##FROM_THEME_DIR=/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$FROM_INSTANCEID/theming/global/images
##TO_THEME_DIR=/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$TO_INSTANCEID/theming/global/images
##if [ -e "$FROM_THEME_DIR" ] ; then
##	[ -e "$TO_THEME_DIR" ] \
##		|| mkdir -p "$TO_THEME_DIR" 
##	[ -e "$FROM_THEME_DIR"/logo ] \
##		&& @ mv -f \
##			"$FROM_THEME_DIR/logo" \
##			"$TO_THEME_DIR"
##	[ -e "$FROM_THEME_DIR"/background ] \
##		&& @ mv -f \
##			"$FROM_THEME_DIR/background" \
##			"$TO_THEME_DIR"
##fi

@ pct unmount $FROM
@ pct unmount $TO


@ lxc-attach $FROM -- turnkey-occ maintenance:mode --off
@ lxc-attach $TO -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
