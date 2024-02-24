# proxmox-utils (EXPERIMENTAL)

A set of scripts for automating setup and tasks in proxmox.

## TODO
- revise defaults
- separate templates/assets into distribution and user directories
  ...this is needed to allow the user to change the configs without the 
  fear of them being overwritten by git (similar to how config is handlerd)
- might be a good idea to export a specific ct script that can be used 
  for updates for that ct
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

### Proxmox

```shell
sudo apt update && sudo apt upgrade
```

```shell
sudo apt install git make 
```


### Network Bridges

`proxmox-utils` expects there to be at least three bridges:
- `WAN` - connected to the port that faces the external network (either 
  directly of via a router)
- `LAN` - a virtual bridge, not connected to any physical interfaces
- `ADMIN` - connected to a second physical interface used for 
  administrative purposes.

Note their numbers (i.e. the number in `vmbr#`), this will be needed for 
setup.

Note, if the device has more that two ports it is recommended to assign 
first/last ports to wan/admin respectively and clearly mark them as such.


### DNS

Add `10.1.1.1` to the DNS on the Proxmox host node after the `127.0.0.1`
but before whatever external DNS you are using.


### Firewall

Make sure to allow at least `ssh` access to the host node from the `ADMIN` 
interface to allow admin CT's access to the host if needed, this is mostly
needed to allow VPN/ssh administration from outside.

For Proxmox firewall configuration see:
https://pve.proxmox.com/wiki/Firewall


### Recovery strategies

XXX ns/gate are separate nodes for redundancy

XXX ssh facing lan to avoid a single point of failure with gate

XXX emergency access points: ssh and wireguard



## Setup

Get the code:
```shell
git clone https://github.com/flynx/proxmox-utils.git
```
or:
```shell
git clone git@github.com:flynx/proxmox-utils.git
```


For host setup:
```shell
sudo make host
```

Be carefull as this may overwrite existing configuration.


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
