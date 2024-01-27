#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

need ifupdown2


#----------------------------------------------------------------------

readConfig


DFL_WAN_PORT=${DFL_WAN_PORT:-enp5s0}
DFL_ADMIN_PORT=${DFL_ADMIN_PORT:-enp2s0}

# XXX move this to root config...
DFL_HOST_ADMIN_IP=${PROXMOX_ADMIN_IP:-10.0.0.254/24}

SOFTWARE=(
	make
	w3m links
	tree
	qrencode
	htop iftop iotop
	tmux
)


#----------------------------------------------------------------------

# Tools
if xreadYes "# Update system?" UPDATE ; then
	@ apt update
	@ apt upgrade
fi
if xreadYes "# Install additional apps?" APPS ; then
	@ apt install $(SOFTWARE[@])
fi

# Networking
# XXX need to:
#		- bootstrap this
#		- setup the gate, ssh, and wireguard
#		- inalize
if xreadYes "# Create bridges?" BRIDGES ; then
	xread "WAN port: " WAN_PORT 
	xread "ADMIN port: " ADMIN_PORT 
	xread "Host ADMIN IP: " HOST_ADMIN_IP
	xread "Gate ADMIN IP: " GATE_ADMIN_IP

	INTERFACES="${cat bridges.tpl \
		| expandPCTTemplate}"

	# XXX add $INTERFACES to /etc/network/interfaces either before the 
	#		source command or at the end...
	# XXX

	# XXX /etc/hosts

	#@ ifupdown2 -a
fi

# Firewall
if xreadYes "# Update firewall rules?" FIREWALL ; then
	@ cp --backup -i templates/etc/pve/firewall/cluster.fw /etc/pve/firewall/
fi

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
