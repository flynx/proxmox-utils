# proxmox-utils (EXPERIMENTAL)

A set of scripts for automating setup and tasks in proxmox.

## TODO
- CT updates / upgrades  
  Right now the simplest way to update the infrastructure CT's if the 
  sources changed is to simply rebuild them -- add rebuild command.
    - backup
    - build (new reserve)
    - destroy
    - clone
    - cleanup
- backup/restore
- config manager -- save/use/..
- mail server
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

Fun.


## Architecture

### Goals

- _Separate concerns_  
  Preferably one service/role per CT
- _Keep things as light as possible_  
  This for the most part rules out Docker as a nested virtualization
  layer under Proxmox, and preferring light distributions like Alpine
  Linux
- _Pragmatic simplicity_  
  This goal yields some compromises to previous goals, for example 
  [TKL](https://www.turnkeylinux.org/) is used as a base for 
  [Nextcloud](https://nextcloud.com/) effectively simplifying the setup 
  and administration of all the related components at the cost of a 
  heavier CT, transparently integrating multiple related services


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
- _LAN_  
  Hosts all the service CT's (`*.srv`)
- _ADMIN_  
  Used for administration (`*.adm`)

The ADMIN network is connected to the admin port.

Both networks are provided DNS and DHCP services by the `ns` CT.

Services on either network are connected to the outside world (WAN) via 
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
- [`wireguard`](https://www.wireguard.com/) VPN (CT) via `gate` reverse proxy,
- `ssh` service (CT) via the `gate` reverse proxy,
- `ssh` service (CT) via the direct `$WAN_SSH_IP` (fail-safe).



## Getting started

### Prerequisites

Install Proxmox and connect it to your device/network.

Proxmox will need to have access to the internet to download assets and 
updates.

Note that Proxmox repositories must be configured for `apt` to work 
correctly, i.e. either _subsctiprion_ or _no-subscribtion_ repos must be 
active and working, for more info rfer to: 
https://pve.proxmox.com/wiki/Package_Repositories


#### Notes

This setup will use three IP addresses:
1. The static (usually) IP initially assigned to Proxmox on install. This 
  will not be used after setup is done,
2. WAN IP address to be used for the main set of applications, this is 
  the address that all the requests will be routed from to various 
  services on the LAN network,
3. Fail-safe ssh IP address, this is the connection used for recovery 
  in case the internal routing fails.



### Setup

Open a terminal on the host, either `ssh` (recommended) or via the UI.

Optionally, set a desired default editor (default: `nano`) via:
```shell
export EDITOR=nano
```

Download the [`bootstrap.sh`](./scripts/bootstrap.sh) script and execute it:
```shell
curl -O 'https://raw.githubusercontent.com/flynx/proxmox-utils/refs/heads/master/scripts/bootstrap.sh' && sudo bash bootstrap.sh
```

_It is recommended to review the script/code before starting._

This will:
- Install basic dependencies,
- Clone this repo,
- Run `make bootstrap` on the repo:
  - bootstrap configure the network (2 out of 3 stages)
  - build and infrastructure start CT's (`gate`, `ns`, `ssh`, and `wireguard`)

At this point WAN interface exposes two IPs:
- Main server (config: `$DFL_WAN_IP` / `$WAN_IP`)
  - ssh:23
  - wireguard:51820
- Fail-safe ssh (config: `$DFL_WAN_SSH_IP` / `$WAN_SSH_IP`)
  - ssh:22

The Proxmox administrative interface is available behind the 
[Wireguard](https://www.wireguard.com/) proxy on the WAN port or directly 
on the ADMIN port, both on https://10.0.0.254:8006.

At this point, it is recommended to check both the fail-safe `ssh` 
connection now and the Wireguard access.

Additional administrative tasks can be performed now if needed.

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

_Note that the ADMIN port is configured for direct connections only, 
connecting it to a configured network can lead to unexpected behavior -- 
DHCP races, IP clashes... etc._



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



## Services

Install all user services:
```shell
make all
```

Includes:
- [`syncthing`](#syncthing)
- [`nextcloud`](#nextcloud)


Install development services:
```shell
make dev
```

Includes:
- [`gitea`](#gitea)



### Syncthing

```shell
make syncthing
```

Syncthing administration interface is accessible via https://syncthing.adm/ 
on the ADMIN network, it is recommended to set an admin password on 
the web interface as soon as possible.

No additional routing or network configuration is required, Syncthing is
smart enough to handle its own connections itself.

For more info see: https://syncthing.net/


### Nextcloud

```shell
make nextcloud
```

Nextcloud will get mapped to subdomain `$NEXTCLOUD_SUBDOMAIN` of 
`$NEXTCLOUD_DOMAIN` (defaulting to `$DOMAIN`, if not defined).

For basic configuration edit the generated: [config.global](./config.global) 
and for defaults: [config.global.example](./config.global.example).

For deeper management use the [TKL](https://www.turnkeylinux.org/) consoles 
(via https://nextcloud.srv, on the LAN network) and `ssh`, for more details 
see: https://www.turnkeylinux.org/nextcloud

For more info on Nextcloud see: https://nextcloud.com/


### Gitea

```shell
make gitea
```

Gitea is mapped to the subdomain `$GITEA_SUBDOMAIN` of `$GITEA_DOMAIN` 
or `$DOMAIN` if the former is not defined.

For basic configuration edit the generated: [config.global](./config.global) 
and for defaults: [config.global.example](./config.global.example).

For more info see: https://gitea.com/


### Custom services

XXX traefik rules




<!--
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
-->


## Extending

### Directory structure

```
proxmox-utils/
+- <ct-type>/
|   +- templates/
|   |   +- ...
|   +- assets/
|   |   +- ...
|   +- staging/
|   |   +- ...
|   +- make.sh
|   +- config
|   +- config.last-run
+- ...
+- Makefile
+- config.global
+- config.global.example
```



## Recovery and Troubleshooting

- Configuration or bridge failure while bootstrapping

  Remove all the CT's that were created by make:
  ```shell
  pct destroy ID
  ```

  Cleanup the interfaces:
  ```shell
  make clean-interfaces
  ```

  Revise configuration if `./config.global`

  Cleanup CT cached configuration:
  ```shell
  make clean
  ```

  Rebuild the bridges:
  ```shell
  make host-bootstrap
  ```
  And select (type "y") "Create bridges" while rejecting all other sections.

  Or, do a full rebuild selecting/rejecting the appropriate sections:
  ```shell
  make bootstrap
  ```


- Failure while creating the `gate` CT

  Check if the bridges are correct, and check if the host as internet access.

  Remove the `gate` CT (replacing 110 if you created it with a different ID):
  ```shell
  pct destroy 110
  ```

  Build the bootstrapped gate:
  ```shell
  make gate-bootstrap
  ```

  Check if gate is accesable and if it has internet access.

  Then create the base CT's:
  ```shell
  make ns ssh wireguard
  ```

  finally cleanup:
  ```shell
  make bootstrap-clean
  ```

  now the setup can be finalized (see: [Setup](#setup))



- Failure while creating other CT's

  Check if gate is accesable and if it has internet access, if it is not
  then this will fail, check or rebuild the gate.

  Simply remove the CT
  ```shell
  pct destroy ID
  ```

  Then rebuild it:
  ```shell
  make CT_NAME
  ```



- Full clean rebuild

  Remove any of the base CT's:
  ```shell
  pct destroy ID
  ```

  Restore bridge configuration:
  ```shell
  make clean-interfaces
  ```

  Cleanup the configuration data:
  ```shell
  make clean-all
  ```

  Follow the instructions in [Setup](#setup)



