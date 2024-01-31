#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

need ifreload


#----------------------------------------------------------------------

readConfig


DFL_WAN_PORT=${DFL_WAN_PORT:-enp5s0}
DFL_ADMIN_PORT=${DFL_ADMIN_PORT:-enp2s0}

DFL_HOST_ADMIN_IP=${PROXMOX_ADMIN_IP:-10.0.0.254/24}


SOFTWARE=(
	ifupdown2
	make
	w3m links
	tree
	qrencode
	htop iftop iotop
	tmux
)


# XXX
#readVars


#----------------------------------------------------------------------

# Tools
if xreadYes "# Update system?" UPDATE ; then
	@ apt update
	@ apt upgrade
fi
if xreadYes "# Install additional apps?" APPS ; then
	@ apt install ${SOFTWARE[@]}
fi

# Networking
# XXX need to:
#		- bootstrap this
#		- setup the gate, ssh, and wireguard
#		- inalize
# XXX /etc/hosts
# XXX save config???
# XXX should we do things in ./staging ???
if xreadYes "# Create bridges?" BRIDGES ; then
	xread "WAN port: " WAN_PORT 
	xread "ADMIN port: " ADMIN_PORT 
	xread "Host ADMIN IP: " HOST_ADMIN_IP
	xread "Gate ADMIN IP: " GATE_ADMIN_IP
	readBridgeVars

	# check if new bridges already exist in interfaces...
	if [ -e /etc/network/interfaces ] \
			&& grep -q \
				"vmbr\(${WAN_BRIDGE}\|${LAN_BRIDGE}\|${ADMIN_BRIDGE}\)" \
				/etc/network/interfaces ; then
		conflict=
		for br in WAN_BRIDGE LAN_BRIDGE ADMIN_BRIDGE ; do
			if grep -q "vmbr${!br}" /etc/network/interfaces ; then
				conflict="${conflict}, vmbr${!br} (${br})"
			fi
		done
		echo "ERROR: will not overwrite existing bridges: ${conflict:2}" >&2
		exit 1
	fi

	@ cp /etc/network/interfaces{,.new}

	BRIDGES="$(\
		cat bridges.tpl \
			| expandPCTTemplate WAN_PORT ADMIN_PORT)"

	# XXX add $BRIDGES to /etc/network/interfaces either before the 
	#		source command or at the end...
	# XXX

	# review/apply setup...
	echo "# Review updated: /etc/network/interfaces.new:"
	@ cat /etc/network/interfaces.new
	echo
	if xreadYes "# Apply changes?" ; then
		@ mv -b /etc/network/interfaces{.new,}
		@ ifreload -a
	fi
fi

# Firewall
if xreadYes "# Update firewall rules?" FIREWALL ; then
	@ cp --backup -i templates/etc/pve/firewall/cluster.fw /etc/pve/firewall/
fi

showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
