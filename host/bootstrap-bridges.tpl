
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

auto vmbr${ADMIN_BRIDGE}
iface vmbr${ADMIN_BRIDGE} inet static
        address ${HOST_ADMIN_IP}
        bridge-ports ${BOOTSTRAP_PORT}
        bridge-stp off
        bridge-fd 0
#ADMIN

