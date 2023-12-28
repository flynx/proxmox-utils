#!/usr/bin/env bash
# IP Forwarding
# add to wan interface in: /etc/network/interfaces:
#       post-up echo 1 > /proc/sys/net/ipv4/ip_forward
# or:
#       # sysctl -w net.ipv4.ip_forward=1
#


# Enable traefik config parsing...
TRAEFIC=1


# Enable iptables
#       # apk add iptables iptables-doc
#       # rc-update add iptables 
#       # rc-service iptables save

LAN=lan
WAN=wan


# keep connections while configuring...
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT


# Flush iptables rules
iptables -F
iptables -X
iptables -t nat -F


# Statefull connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Loop-back rules
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# DNS
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT

# ICMP
#iptables -A INPUT -i $WAN -p icmp -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT


# Traefik
if ! [ -z $TRAEFIC ] ; then
	# NOTE: we only open ports here not caring about addresses...
	IFS=$'\n'
	RULES=($(
		cat /etc/traefik/traefik.yaml \
			| grep '^[^#]*address:' \
			| grep -o "\'.*\'"))
	for addr in "${RULES[@]}" ; do
		addr=${addr:1:-1}
		host=${addr/:*}
		port=${addr/*:}

		udp=
		tcp=
		if [[ $port == *udp* ]] ; then
			udp=1
		fi
		if [[ $port == *tcp* ]] ; then
			tcp=1
		fi
		if [ -z $tcp ] && [ -z $udp ] ; then
			tcp=1
			udp=1
		fi
		port=${port/\/*/}

		if ! [ -z $udp ] ; then
			iptables -A INPUT -p udp --dport $port -j ACCEPT 
		fi
		if ! [ -z $tcp ] ; then
			iptables -A INPUT -p tcp --dport $port -j ACCEPT 
		fi
	done
fi



# NAT
iptables -t nat -A POSTROUTING -o $WAN -j MASQUERADE



# Default policies
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
# XXX do we actually need this???
#       ...uncommenting this breaks forwarding...
#iptables -P FORWARD DROP
