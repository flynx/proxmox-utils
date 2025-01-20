#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


# this can be:
# 	full
# 	list
# 	<empty>
MIGRATE_CACHE=${MIGRATE_CACHE:-full}

# NOTE: paths here are relative to appdata_<instance_id>/
MIGRATE_CACHE_FILES=(
	theming/global/images/background
	theming/global/images/logo
	theming/global/images/favicon.ico
)


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


# files...
@ pct mount $FROM
@ pct mount $TO

# mirgate files and data...
@ rsync -Aavx \
	/var/lib/lxc/$FROM/rootfs/var/www/nextcloud-data/ \
	/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data

# migrate cache...
if ! [ -z "$DRY_RUN" ] \
		|| [ -e "$FROM_THEME_DIR" ] ; then
	# instance id's...
	# XXX not sure how to deal with $DRY_RUN here...
	FROM_INSTANCEID=$(lxc-attach $FROM -- turnkey-occ config:system:get instanceid)
	TO_INSTANCEID=$(lxc-attach $TO -- turnkey-occ config:system:get instanceid)

	# full...
	if [ "$MIGRATE_CACHE" == "full" ] ; then
		# migrate theming and other instance files...
		APPDATA=/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$TO_INSTANCEID
		[ -e "$APPDATA" ] \
			&& @ mv -f "$APPDATA" "${APPDATA}.bak"
		@ mv -f \
			/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$FROM_INSTANCEID \
			"$APPDATA"

	# list...
	elif [ "$MIGRATE_CACHE" == "list" ] ; then
		FROM_CACHE_DIR=/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$FROM_INSTANCEID/
		TO_CACHE_DIR=/var/lib/lxc/$TO/rootfs/var/www/nextcloud-data/appdata_$TO_INSTANCEID/
		for f in "${MIGRATE_CACHE_FILES[@]}" ; do
			from=${FROM_CACHE_DIR}/$f
			to=${TO_CACHE_DIR}/$f
			if [ -z "$DRY_RUN" ] \
					&& ! [ -e "$from" ] ; then
				continue
			fi
			@ mkdir -p "$(dirname "$to")"
			@ cp -r "$from" "$to"
		done
	fi
fi

@ pct unmount $FROM
@ pct unmount $TO


@ lxc-attach $FROM -- turnkey-occ maintenance:mode --off
@ lxc-attach $TO -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
