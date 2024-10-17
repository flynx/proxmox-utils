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

BRIDGES_TPL=bootstrap-bridges.tpl

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

# Bridges...
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

	INTERFACES=/etc/network/interfaces

	# check if new bridges already exist in interfaces...
	if [ -e "$INTERFACES" ] \
			&& grep -q \
				"vmbr\(${WAN_BRIDGE}\|${LAN_BRIDGE}\|${ADMIN_BRIDGE}\)" \
				"$INTERFACES" ; then
		conflict=
		for br in WAN_BRIDGE LAN_BRIDGE ADMIN_BRIDGE ; do
			if grep -q "vmbr${!br}" "$INTERFACES" ; then
				conflict="${conflict}, vmbr${!br} (${br})"
			fi
		done
		echo "ERROR: will not overwrite existing bridges: ${conflict:2}" >&2
		exit 1
	fi

	@ cp "$INTERFACES"{,.bak}
	@ cp "$INTERFACES"{,.new}

	BRIDGES="$(\
		cat "$BRIDGES_TPL" \
			| expandPCTTemplate \
				LAN_BRIDGE WAN_BRIDGE ADMIN_BRIDGE \
				WAN_PORT ADMIN_PORT \
				HOST_ADMIN_IP GATE_ADMIN_IP)"

	if [ -z "$DRY_RUN" ] ; then
		# XXX add $BRIDGES to "$INTERFACES" either before the 
		#		source command or at the end...
		# XXX
		echo "$BRIDGES" >> "$INTERFACES".new
	else
		echo "$BRIDGES"
	fi

	if reviewApplyChanges "$INTERFACES" ; then
		if ! @ ifreload -a ; then
			# reset settings back if ifreload fails...
			@ cp "$INTERFACES"{.bak,}
			@ ifreload -a	
		fi
	fi
fi


echo "# Building config..."
# XXX do we need any extra vars here???
buildAssets


# XXX /etc/hosts???


# DNS
if xreadYes "# Update DNS?" DNS ; then
	file=/etc/resolv.conf
	@ cp "staging/${file}" "${file}".new
	reviewApplyChanges "${file}"
fi


# Firewall
if xreadYes "# Update firewall rules?" FIREWALL ; then
	file=/etc/pve/firewall/cluster.fw
	@ cp "staging/${file}" "${file}".new
	reviewApplyChanges "${file}"
fi


showNotes
echo "# Done."



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
