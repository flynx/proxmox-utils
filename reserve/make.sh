#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

CT_PATH=/etc/pve/lxc/

readConfig


#----------------------------------------------------------------------

makeReserveCT(){
	local ID=$1
	local RESERVE_ID=$2
	local TEMPLATE_ID=$3
	local HOSTNAME=$(ct2hostname $ID)

	@ pct shutdown $ID

	@ pct destroy $RESERVE_ID --purge
	@ pct clone $ID $RESERVE_ID --hostname ${HOSTNAME}

	@ pct start $ID

	if [ $TEMPLATE_ID ] ; then
		@ pct destroy $TEMPLATE_ID --purge
		@ pct clone $RESERVE_ID $TEMPLATE_ID --hostname ${HOSTNAME}
		@ pct templates $TEMPLATE_ID
	fi

	# XXX sould this get into the template...
	@ pct set $RESERVE_ID -onboot 0
}

startReserveCT(){
	local ID=$1
	local RESERVE_ID=$2
	local TEMPLATE_ID=$3
	local HOSTNAME=$(ct2hostname $ID)

	@ pct shutdown $ID
	@ pct set $ID -onboot 0

	# XXX check if a reserve is already up then recreate it from template...

	@ pct start $RESERVE_ID
	@ pct set $RESERVE_ID -onboot 1
}


#----------------------------------------------------------------------

xread "Gate ID:" GATE_ID
xread "Gate reserve ID:" RESERVE_GATE_ID
xread "Gate template ID:" TEMPLATE_GATE_ID

xread "NS ID:" NS_ID
xread "NS reserve ID:" RESERVE_NS_ID
xread "NS template ID:" TEMPLATE_NS_ID


#----------------------------------------------------------------------

makeReserveCT $GATE_ID $RESERVE_GATE_ID $TEMPLATE_GATE_ID

makeReserveCT $NS_ID $RESERVE_NS_ID $TEMPLATE_NS_ID

saveLastRunConfig

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
