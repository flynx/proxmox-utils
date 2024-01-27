
auto vmbr0
iface vmbr0 inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
#LAN

auto vmbr1
iface vmbr2 inet manual
        bridge-ports ${WAN_PORT}
        bridge-stp off
        bridge-fd 0
#WAN

auto vmbr2
iface vmbr3 inet static
        address ${HOST_ADMIN_IP}
        gateway ${GATE_ADMIN_IPn}
        bridge-ports ${ADMIN_PORT}
        bridge-stp off
        bridge-fd 0
#ADMIN

