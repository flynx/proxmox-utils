# proxmox-utils (EXPERIMENTAL)

A set of scripts for automating setup and tasks in proxmox.

## TODO
- CT updates
- backup/restore
- mail
- which is better?
  - Makefile (a-la ./wireguard/templates/root/Makefile)
  - shell (a-la ./shadow/templates/root/update-shadowsocks.sh)
- separate templates/assets into distribution and user directories
  ...this is needed to allow the user to change the configs without the 
  fear of them being overwritten by git (similar to how config is handlerd)


<!-- START doctoc -->
<!-- END doctoc -->



## Motivation

This was simply faster to implement than learning and writing the same 
functionality in Ansible.

_NOTE: for a fair assessment of viability of further development an 
Ansible version will be implemented next as a direct comparison._


## Architecture

### Goals

- Separate concerns  
  Preferably one service/role per CT
- Keep things as light as possible  
  This for the most part rules out Docker as a nested virtualization
  layer under Proxmox while preferring light distributions like Alpine
  Linux
- Pragmatic simplicity  
  This goal yields some compromises to previous goals, for example [TKL]()
  is used as a base for [Nextcloud]() effectively simplifying the setup 
  and administration of all the related components at the cost of a 
  heavier CT transparently integrating multiple related services


### Network

```
    Internet                                              Admin 
       v                                                    v
  +----|----------------------------------------------------|-----+  
  |    |                                                    |     |  
  |  (wan)                                (lan)          (admin)  |  
  |    |                                    |               |     |  
  |    |                                    |         pve --+     |  
  |    |                                    |               |     |  
  |    |                   +--------------------------------+     |  
  |    |                  /                 |               |     |  
  |    +--($WAN_SSH_IP)- ssh ---------------+               |     |  
  |    |                  ^                 |               |     |  
  |    |              (ssh:23)              |               |     |  
  |    |                  .                 |               |     |  
  |    |                  . +------------------------(nat)--+     |  
  |    |                  ./                |               |     |  
  |    +------($WAN_IP)- gate ------(nat)---+               |     |  
  |                       .                 |               |     |  
  |                       .                 +-- ns ---------+     |  
  |                       .                 |               |     |  
  |                       + - (udp:51820)-> +-- wireguard --+     |  
  | System                .                 |               |     |  
  | - - - - - - - - - - - . - - - - - - - - | - - - - - - - | - - |  
  | Application           .                 +-- syncthing --+     |  
  |                       .                 |                     |  
  |                       + - - - (https)-> +-- nextcloud         |  
  |                       .                 |                     |  
  |                       + - (ssh/https)-> +-- gitea             |  
  |                                                               |  
  +---------------------------------------------------------------+  
```

The system defines two networks:
- LAN  
  Hosts all the service CT's (`*.srv`)
- ADMIN  
  Used for administration (`*.adm`)

The ADMIN network is connected to the admin port.

Both networks are provided DNS and DHCP services by the `ns` CT.

Services on both networks are connected to the outside world (WAN) via 
a NAT router implemented by the `gate` CT (`iptables`).

The `gate` CT also implements a reverse proxy ([`traefik`](https://traefik.io/traefik/)), 
routing requests from the WAN (`$WAN_IP`) to appropriate service CT's on 
the LAN.

Services expose their administration interfaces only on the ADMIN network
when possible.

The host Proxmox (`pve.adm`) is only accessible through the ADMIN network.

The `gate` and `ns` CT's are only accessible for administration from the 
host (i.e. via `lxc-attach ..`).

Three ways of access to the ADMIN network are provided:
- `ssh` service (CT) via the `gate` reverse proxy
- `wireguard` VPN (CT) via `gate` reverse proxy
- `ssh` service (CT) via the direct `$WAN_SSH_IP` (fail-safe)



## Setup

### Prerequisites

Install Proxmox and connect it to your device/network.

Proxmox will need to have access to the internet to download assets and 
updates.


#### Notes

This setup will use three IP addresses:
1. The static (usually) IP initially assigned to Proxmox on install. This 
  will not be used after setup is done,
2. WAN IP address to be used for the main set of applications, this is 
  the address that all the requests will be routed from to various 
  services internally,
3. Fail-safe ssh IP address, this is the connection used for recovery 
  in case the internal routing fails.



### Semi-automated setup

Open a terminal on the host (`ssh` or via the UI).

Optionally, set a desired default editor via:
```shell
export EDITOR=nano
```

Download the [`bootstrap.sh`](./scripts/bootstrap.sh) script and execute it:
```shell
curl 'https://raw.githubusercontent.com/flynx/proxmox-utils/refs/heads/master/scripts/bootstrap.sh' | sudo bash
```

This will:
- Install basic dependencies
- Clone this repo
- Run `make bootstrap` on the repo

After the basic setup is done connect the device to the network via the 
selcted WAN port and **disconnect** the ADMIN port.

The WAN interface exposes two IPs:
- Main server (config: `$DFL_WAN_IP` / `$WAN_IP`)
  - ssh:23
  - wireguard:51820
- Fail-safe ssh (config: `$DFL_WAN_SSH_IP` / `$WAN_SSH_IP`)
  - ssh:22


The Proxmox administrative interface is available behind the Wireguard 
proxy or on the ADMIN port, both on https://10.0.0.254:8006.

To finalize the setup run:
```shell
make finalize
```

This will
- Setup firewall rules.  
  Note that the firewall will not be enabled, this should be done manually
  after rule review.
- Detach the host from any external ports and make it accessible only 
  from the internal network.  
  See: [Architecture](#architecture) and [Bootstrapping](#bootstrapping)

This will break the ssh connection when done, reconnect via the WAN port 
to continue (see: [Accessing the host](#accessing-the-host)), or connect 
directly to the ADMIN port (DHCP) and ssh into `$HOST_ADMIN_IP` (default: 10.0.0.254).


_Note that the ADMIN port is configured for direct connections only (DHCP), 
connecting it to a configured network can lead to unexpected behavior._



#### Accessing the host

The simplest way is to connect to `wireguard` VPN and open http://pve.adm:8006 
in a browser (a profile was created during the setup process and stored 
in the `/root/clients/` directory on the `wireguard` CT).

The second approach is to `ssh` to either:

```shell
ssh -p 23 <user>@<WAN_IP>
```

or:
```shell
ssh <user>@<WAN_SSH_IP>
```

The later will also work if the `gate` CT is down or not accessible.


And from the `ssh` CT:
```shell
ssh root@pve
```

_WARNING: NEVER store any ssh keys on the `ssh` CT, use `ssh-agent` instead!_



#### Configuration

XXX

The following CT's interfaces can not be configured in the Proxmox UI:
- `gate`
- `ns`
- `nextcloud`
- `wireguard`

This is done mostly to keep Proxmox from touching the `hostname $(hostname)`
directive (used by the DNS server to assigned predefined IP's) and in 
the case of `gate` and `wireguard` to keep it from touching the additional 
bridges or interfaces defined.  
(XXX this restriction may be lifted in the future)



#### Setup additional services

XXX

```shell
make all
```

```shell
make dev
```


Or individually:
```shell
make nextcloud
```

```shell
make syncthing
```

```shell
make gitea
```


#### Setup and configure custom services

XXX traefik rules





### Manual setup


#### Bootstrapping

Since all the internal traffic is routed through the `gate` we need both 
the bridges and it setup for things to work, thus we first bootstrap the
bridges, create the basic infrastructure and then finalize the setup.

Bootsrapping is done in three stages:
1. Bootstrap: 
  ```shell
  make bootstrap
  ```
  - Create the needed bridges
  - Create the infrastructure CT's (`gate`, `ns`, `ssh`, ...)
2. Cleanup: 
  ```shell
  make bootstrap-clean
  ```
  - Route the `host` through the `gate`
3. Finalize: 
  ```shell
  make finalise
  ```
  - disconnect the `host` from the non-ADMIN networks


After the final stage two physical ports will be active, the ADMIN port 
and the WAN port, the former is by default the same port set by Proxmox 
setup, the WAN port is the port selected during the stup stage. All the 
services will be listening on the WAN port while the admin port is used 
only for administration and recovory cases.



#### Network Bridges

`proxmox-utils` expects there to be at least three bridges:
- `WAN` (`vmbr_wan`) - connected to the port that faces the external 
  network (either directly of via a router)
- `LAN` (`vmbr_lan`) - a virtual bridge, not connected to any physical 
  interfaces
- `ADMIN` (`vmbr_admin`) - connected to a second physical interface used 
  for administrative purposes.

Created via:
```shell
make host-bootstrap
```

Updated by:
```shell
make host-bootstrap-clean
```

and:
```shell
make finalize
```

If the device has more that two ports it is recommended to assign 
first/last ports to wan/admin respectively and clearly mark them as such.



#### DNS

Add `10.1.1.1` to the DNS on the Proxmox host node after the `127.0.0.1`
but before whatever external DNS you are using.

Donw via:
```shell
make host
```

or:
```shell
make host-bootstrap
```


#### Firewall

Make sure to allow at least `ssh` access to the host node from the `ADMIN` 
interface to allow admin CT's access to the host if needed, this is mostly
needed to allow VPN/ssh administration from outside.

Donw via:
```shell
make host
```

or:
```shell
make host-bootstrap
```

For Proxmox firewall configuration see:
https://pve.proxmox.com/wiki/Firewall


### Recovery strategies

XXX ns/gate are separate nodes for redundancy

XXX ssh facing lan to avoid a single point of failure with gate

XXX emergency access points: ssh and wireguard



## Misc

Install CT's:
```shell
sudo make all
```

Install gitea (optional):
```shell
sudo make dev
```


## Post-setup

XXX test conections
XXX change proxmox ip/network
XXX firewall


## Extending

### Directory structure

```
/
+- <ct-type>/
|   +- templates/
|   +- assets/
|   +- staging/
|   +- make.sh
|   +- config
|   +- config.last-run
+- ...
+- Makefile
+- config.global
+- config.global.example
```
