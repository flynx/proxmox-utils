#!/usr/bin/bash
#----------------------------------------------------------------------

cd $(dirname $0)
PATH=$PATH:$(dirname "$(pwd)")


#----------------------------------------------------------------------

source ../.pct-helpers


#----------------------------------------------------------------------

readConfig


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
if xreadYes "# Create bridges?" BRIDGES ; then
	echo
fi

# Firewall
if xreadYes "# Update firewall rules?" FIREWALL ; then
	@ cp --backup -i templates/etc/pve/firewall/cluster.fw /etc/pve/firewall/
fi




#----------------------------------------------------------------------
# vim:set ts=4 sw=4 :
