
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
        gateway ${GATE_ADMIN_IPn}
        bridge-ports ${ADMIN_PORT}
        bridge-stp off
        bridge-fd 0
#ADMIN

