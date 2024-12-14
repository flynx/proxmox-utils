#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


#----------------------------------------------------------------------
# Restore backup...
# see:
# 	https://docs.nextcloud.com/server/latest/admin_manual/maintenance/restore.html




#----------------------------------------------------------------------

# XXX confirm vars...
# XXX

@ lxc-attach $ID -- turnkey-occ maintenance:mode --on

# XXX

@ lxc-attach $ID -- turnkey-occ maintenance:mode --off



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
