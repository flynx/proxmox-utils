#----------------------------------------------------------------------
#
#
# TODO:
# - cleanup/destroy
# - update
# - backup
# - pull config
#
#----------------------------------------------------------------------

# NOTE: The order here is important: 
# 	- to avoid bootstrapping network connections gate must be the 
# 	  first CT to get built to route the rest of CT's to the WAN 
# 	  connection during the build process.
# 	- ns should be the second to be built to provide the rest of the
# 	  CT's with DHCP network configuration.
# 	- the rest of the CT's are created in order of importance, strting 
# 	  from CT's needed for access and ending with services.
CTs := \
       gate \
       ns \
       ssh \
       wireguard \
       syncthing \
       nextcloud \
       gitea



#----------------------------------------------------------------------

.PHONY: FORCE
FORCE:


%: %/make.sh FORCE
	$<


config.global: config.global.example
	vim "+0r config.global.example" $@



#----------------------------------------------------------------------
# Shorthands...

.PHONY: config
config: config.global


.PHONY: gate
gate: gate-traefik



#----------------------------------------------------------------------

.PHONY: all
all: config $(CTs) 




#----------------------------------------------------------------------
