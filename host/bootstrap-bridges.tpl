
# NOTE: this assumes the ADMIN bridge to exist (proxmox default) and to be vmbr0...

auto vmbr${LAN_BRIDGE}
iface vmbr${LAN_BRIDGE} inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
#LAN

auto vmbr${WAN_BRIDGE}
iface vmbr${WAN_BRIDGE} inet manual
        bridge-ports ${WAN_PORT}
        bridge-stp off
        bridge-fd 0
#WAN

