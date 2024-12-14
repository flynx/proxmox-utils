#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------
# 
# see:
# 	https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html	

# XXX confirm vars...
# XXX

DATE=$(date +%Y%m%d%H%M)
DIR=${DATE}-${CTHOSTNAME}-${ID}



#----------------------------------------------------------------------

mkdir "${DIR}"
cd "${DIR}"

@ lxc-attach $ID -- turnkey-occ maintenance:mode --on

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
pct mount $ID
rsync -Aavx /var/lib/lxc/$ID/rootfs/var/www/nextcloud-data .
pct unmount $ID

@ lxc-attach $ID -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
