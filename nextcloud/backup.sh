#!/usr/bin/bash
#----------------------------------------------------------------------

#cd $(dirname $0)
#PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------
# handle args...

usage(){
	echo "$0 ID [DIR]"
}

# XXX 



#----------------------------------------------------------------------
# 
# see:
# 	https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html	

BACKUPDIR=${BACKUPDIR:=backup}

DATE=$(date +%Y%m%d%H%M)

xread "ID: " ID

# XXX confirm??
CTHOSTNAME=$(ct2hostname $ID)


DIR=${BACKUPDIR}/${DATE}-${CTHOSTNAME}-${ID}

echo "# BACKUP: $DIR"



#----------------------------------------------------------------------

@ mkdir -p "${DIR}"
@ cd "${DIR}"

@ lxc-attach $ID -- turnkey-occ maintenance:mode --on

# XXX should we sleep here for a minute or 6 as is recommended in the docs???

# sql...
# XXX db:
# 	mysqldump --single-transaction \
# 		-h [server] -u [username] -p[password] \
# 		[db_name] \
# 		> nextcloud-sqlbkp_`date +"%Y%m%d"`.bak	
# or:
#	mysqldump --single-transaction --default-character-set=utf8mb4 \
#		-h [server] -u [username] -p[password] \
#		[db_name] \
#		> nextcloud-sqlbkp_`date +"%Y%m%d"`.bak
@ lxc-attach $ID -- mysqldump --single-transaction nextcloud > nextcloud.sql

# files...
@ pct mount $ID
# XXX should this be an incremental backup/sync??? (i.e. removing deleted files (to a dir))???
# 		...ask user / option??
@ rsync -Aavx /var/lib/lxc/$ID/rootfs/var/www/nextcloud-data .
@ pct unmount $ID

@ lxc-attach $ID -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
