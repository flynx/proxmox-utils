#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------




#----------------------------------------------------------------------

@ lxc-attach $FROM -- turnkey-occ maintenance:mode --on
@ lxc-attach $TO -- turnkey-occ maintenance:mode --on

# sql
@ lxc-attach $TO -- mysql -e "DROP DATABASE nextcloud"
@ lxc-attach $TO -- mysql -e "CREATE DATABASE nextcloud"
@@ "lxc-attach $FROM -- mysqldump --single-transaction nextcloud \
	| lxc-attach $TO -- mysql nextcloud"

# files...
pct mount $FROM
pct mount $TO
rsync -Aavx \
	/var/lib/lxc/$FROM/rootfs/var/www/nextcloud-data
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data
pct unmount $FROM
pct unmount $TO

@ lxc-attach $FROM -- turnkey-occ maintenance:mode --off
@ lxc-attach $TO -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
