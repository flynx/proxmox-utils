#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------

# XXX handle commandline args...

usage(){
	echo "$0 FROM TO"
}

# XXX should we check for >2 ???
if [ $# != 2 ] ; then
	usage
	echo "Not enough arguments."
	exit 1
fi

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

# files...
@ pct mount $FROM
@ pct mount $TO
@ rsync -Aavx \
	/var/lib/lxc/$FROM/rootfs/var/www/nextcloud-data
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data
@ pct unmount $FROM
@ pct unmount $TO

@ lxc-attach $FROM -- turnkey-occ maintenance:mode --off
@ lxc-attach $TO -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
