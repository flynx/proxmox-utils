# proxmox-utils (EXPERIMENTAL)

A set of scripts for automating setup and tasks in proxmox.

## TODO
- revise defaults
- separate templates/assets into distribution and user directories
  ...this is needed to allow the user to change the configs without the 
  fear of them being overwritten by git (similar to how config is handlerd)
- might be a good idea to export a specific ct script that can be used 
  for updates for that ct
- which is better?
  - Makefile (a-la wireguard)
  - shell (a-la shadow)
- ct updates
- backup/restore
- mail


## Motivation

This was simply faster to implement than learning and writing the same 
functionality in Ansible.

_NOTE: for a fair assessment of viability of further development an 
Ansible version will be implemented next as a direct comparison._


## Architecture

Goals:
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

XXX service structure

XXX network

In general `proxmox-utils` splits the configuration into two levels:


### CT level  

This level is handled by the `Makefile` and is almost completely automated


### Host level

This level depends on the host setup and is currently done manually 
depending on existing host configuration.

XXX clean setup scripts...
  


## Prerequisites

Install Proxmox and connect it to your network.


## Semi-automated setup

This will download the [`bootstrap.sh`](./bootstrap.sh) script and execute it:
```shell
curl 'https://raw.githubusercontent.com/flynx/proxmox-utils/refs/heads/master/bootstrap.sh' | sudo bash
```

This will:
- Install basic dependencies
- Clone this repo
- Run `make bootstrap` on the repo

After the basic setup is done connect the device to the network via the 
selcted WAN port and it is reccomended to disconnect the admin PORT.

The WAN interface exposes two IPs:
- Main server (config: `DFL_WAN_IP` / `WAN_IP`)
  - ssh:23
  - wireguard:51820
- Fail-safe ssh (config: `DFL_WAN_SSH_IP` / `WAN_SSH_IP`)
  - ssh:22

The Proxmox administrative interface is available behind the Wireguard 
proxy or on the ADMIN port, both on https://10.0.0.254:8006.


XXX setup additional CTs...


XXX configuration / administration...



## Manual setup


### Bootstrapping

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



### Network Bridges

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



### DNS

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


### Firewall

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
