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

INTERFACES=/etc/network/interfaces

BOOTSTRAP_PORT=${BOOTSTRAP_PORT:-none}

BRIDGES_TPL=${BRIDGES_TPL:-bridges.tpl}

# XXX
#readVars


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Bootstrap...

# cleanup...
if ! [ -z $BOOTSTRAP_CLEAN ] ; then
	@ cp "$INTERFACES"{,.bak}

	__finalize(){
		if reviewApplyChanges "$INTERFACES" apply ; then
			# XXX this must be done in nohup to avoid breaking on connection lost...
			if ! @ ifreload -a ; then
				# reset settings back if ifreload fails...
				@ cp "$INTERFACES"{.bak,}
				@ ifreload -a	
			fi
		fi
		# clear self to avoid a second deffered execution...
		unset -f __finalize
	}

	# stage 1: bootstrap -> clean
	if [ -e "$INTERFACES".clean ] ; then
		@ mv "$INTERFACES"{.clean,.new}
		DFL_UPDATE=SKIP
		DFL_APPS=SKIP
		DFL_BRIDGES=SKIP
		DFL_HOSTS=SKIP
		DFL_DNS=1
		DFL_FIREWALL=SKIP

		# NOTE: in general this is non-destructive and can be done inline.
		__finalize

	# stage 2: clean -> final
	elif [ -e "$INTERFACES".final ] ; then
		@ mv "$INTERFACES"{.final,.new}
		DFL_UPDATE=SKIP
		DFL_APPS=SKIP
		DFL_BRIDGES=SKIP
		DFL_HOSTS=1
		DFL_DNS=SKIP
		DFL_FIREWALL=1

		# NOTE: __finalize is deferred to just before reboot...

		REBOOT=1

	# done
	else
		exit
	fi

# Bootstrap...
elif ! [ -z $BOOTSTRAP ] ; then
	DFL_BOOTSTRAP_PORT=${DFL_BOOTSTRAP_PORT:-none}
	xread "Bootstrap port: " BOOTSTRAP_PORT

	BRIDGES_BOOTSTRAP_TPL=bootstrap-bridges.tpl

	DFL_UPDATE=1
	DFL_APPS=1
	DFL_BRIDGES=1
	DFL_HOSTS=SKIP
	DFL_DNS=SKIP
	DFL_FIREWALL=SKIP
fi



#----------------------------------------------------------------------

# system...
if xreadYes "# Update system?" UPDATE ; then
	@ apt update
	@ apt upgrade
fi


# tools...
if xreadYes "# Install additional apps?" APPS ; then
	@ apt install ${SOFTWARE[@]}
fi


# bridges...
if xreadYes "# Create bridges?" BRIDGES ; then
	xread "WAN port: " WAN_PORT 
	xread "ADMIN port: " ADMIN_PORT 
	xread "Host ADMIN IP: " HOST_ADMIN_IP
	xread "Gate ADMIN IP: " GATE_ADMIN_IP
	readBridgeVars

	# check if new bridges already exist in interfaces...
	if [ -e "$INTERFACES" ] \
			&& grep -q \
				"vmbr\(${WAN_BRIDGE}\|${LAN_BRIDGE}\|${ADMIN_BRIDGE}\)" \
				"$INTERFACES" ; then
		conflict=
		#for br in WAN_BRIDGE LAN_BRIDGE ADMIN_BRIDGE ; do
		for br in WAN_BRIDGE LAN_BRIDGE ; do
			if grep -q "vmbr${!br}" "$INTERFACES" ; then
				conflict="${conflict}, vmbr${!br} (${br})"
			fi
		done
		if grep -q "vmbr${ADMIN_BRIDGE}" "$INTERFACES" ; then
			echo "NOTE: reusing vmbr${ADMIN_BRIDGE} for ADMIN."
		else
			echo "ERROR: will not overwrite existing bridges: ${conflict:2}" >&2
			exit 1
		fi
	fi

	# interfaces.orig: backup...
	[ -e "${INTERFACES}.orig" ] \
		|| @ cp "${INTERFACES}"{,.orig}
	@ cp "$INTERFACES"{,.bak}
	@ cp "$INTERFACES"{,.new}

	BRIDGES="$(\
		cat "$BRIDGES_TPL" \
			| expandPCTTemplate \
				LAN_BRIDGE WAN_BRIDGE ADMIN_BRIDGE BOOTSTRAP_BRIDGE \
				WAN_PORT ADMIN_PORT BOOTSTRAP_ADMIN_PORT \
				HOST_ADMIN_IP GATE_ADMIN_IP)"

	[ -z $BRIDGES_BOOTSTRAP_TPL ] \
		|| BRIDGES_BOOTSTRAP="$(\
			cat "$BRIDGES_BOOTSTRAP_TPL" \
				| expandPCTTemplate \
					LAN_BRIDGE WAN_BRIDGE ADMIN_BRIDGE BOOTSTRAP_BRIDGE \
					WAN_PORT ADMIN_PORT BOOTSTRAP_PORT \
					HOST_ADMIN_IP GATE_ADMIN_IP)"

	if [ -z "$DRY_RUN" ] ; then
		# write both bootstrap and clean bridge configurations...
		if ! [ -z $BRIDGES_BOOTSTRAP ] ; then

			# interfaces.final
			@ cp "$INTERFACES"{.new,.final}
			@ sed -i \
				-e 's/'$ADMIN_PORT'/'$BOOTSTRAP_PORT'/' \
				-e '/^.*gateway .*$/d' \
				"$INTERFACES".final
			echo "$BRIDGES" \
				>> "$INTERFACES".final

			# interfaces.clean
			@ cp "$INTERFACES"{.new,.clean}
			@ sed -i \
				-e '/^.*gateway .*$/d' \
				"$INTERFACES".clean
			echo "$BRIDGES" \
				| sed \
					-e 's/'$ADMIN_PORT'/'$BOOTSTRAP_PORT'/' \
				>> "$INTERFACES".clean

			# interfaces.new (prep)
			BRIDGES=$(\
				echo "$BRIDGES_BOOTSTRAP" \
					| sed -e '/^.*gateway .*$/d')
		fi

		# interfaces.new
		echo "$BRIDGES" >> "$INTERFACES".new

	else
		echo "$BRIDGES"
	fi

	# interfaces
	if reviewApplyChanges "$INTERFACES" apply ; then
		# XXX this must be done in nohup to avoid breaking on connection lost...
		if ! @ ifreload -a ; then
			# reset settings back if ifreload fails...
			@ cp "$INTERFACES"{.bak,}
			@ ifreload -a	
		fi
	fi
fi


# /etc/hosts
if xreadYes "# Update /etc/hosts?" HOSTS ; then
	@ cp /etc/hosts{,.bak}
	@ cp /etc/hosts{,.new}
	@ sed -i \
		-e 's/^[^#].* \(pve.local.*\)$/'${HOST_ADMIN_IP/\/*}' \1/' \
		/etc/hosts.new
	reviewApplyChanges /etc/hosts apply
fi


# build only if we need to...
build(){
	if [ -z $__ASSETS ] ; then
		__ASSETS=1
		echo "# Building config templates..."
		buildAssets
	fi
}


# DNS
if xreadYes "# Update DNS?" DNS ; then
	build
	file=/etc/resolv.conf
	@ cp "staging/${file}" "${file}".new
	reviewApplyChanges "${file}" apply
fi


# Firewall
if xreadYes "# Update firewall rules?" FIREWALL ; then
	build
	file=/etc/pve/firewall/cluster.fw
	@ cp "staging/${file}" "${file}".new
	reviewApplyChanges "${file}" apply
fi


showNotes
echo "# Done."


# finalize...
if [[ $( type -t __finalize ) == "function" ]] ; then
	echo "# Finalizing ${INTERFACES}..."
	__finalize
fi


# reboot...
if ! [ -z $REBOOT ] ; then
	echo "# Rebooting..."
	@ reboot
fi



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
