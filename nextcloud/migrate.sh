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

FROM_INSTANCEID=$(lxc-attach $FROM -- turnkey-occ config:system:get instanceid)
TO_INSTANCEID=$(lxc-attach $TO -- turnkey-occ config:system:get instanceid)

# XXX should we sleep here for a minute or 6 as is recommended in the docs???

# sql
@ lxc-attach $TO -- mysql -e "DROP DATABASE nextcloud"
@ lxc-attach $TO -- mysql -e "CREATE DATABASE nextcloud"
@@ "lxc-attach $FROM -- mysqldump --single-transaction nextcloud \
	| lxc-attach $TO -- mysql nextcloud"

# files...
@ pct mount $FROM
@ pct mount $TO
# XXX need to also copy the logo and bg images...
# 		path seems to be:
#			INSTANCEID=$(lxc-attach $ID -- turnkey-occ config:system:get instanceid)
# 			nextcloud-data/appdata_$INSTANCEID/theming/global/images/background
@ rsync -Aavx \
	/var/lib/lxc/$FROM/rootfs/var/www/nextcloud-data/ \
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data
# migrate cache and background/logo images... (XXX TEST)
@ mv -f \
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$TO_INSTANCEID{,.bak}
@ mv -f \
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_{$FROM_INSTANCEID,$TO_INSTANCEID}
@ pct unmount $FROM
@ pct unmount $TO

@ lxc-attach $FROM -- turnkey-occ maintenance:mode --off
@ lxc-attach $TO -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
