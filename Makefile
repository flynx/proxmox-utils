#----------------------------------------------------------------------
#
#
# TODO:
# - cleanup/destroy
# - update
# - backup
# - pull config
#
#
#----------------------------------------------------------------------

EDITOR ?= vim


# CTs...
#
# NOTE: The order here is important: 
# 	- to avoid bootstrapping network connections gate must be the 
# 	  first CT to get built to route the rest of CT's to the WAN 
# 	  connection during the build process.
# 	- ns should be the second to be built to provide the rest of the
# 	  CT's with DHCP network configuration.
# 	- the rest of the CT's are created in order of importance, strting 
# 	  from CT's needed for access and ending with services.
CORE_CTs := \
	gate ns
MINIMAL_CTs := \
	ssh wireguard 
APP_CTs := \
	syncthing nextcloud #gitea
# Optional (see dev target)...
DEV_CTs := \
	gitea


DEPENDENCIES = make git dig pct



#----------------------------------------------------------------------
# dependency checking...

require(%):
	@printf "%-20s %s\n" \
		"$*" \
		"`which $* &> /dev/null && echo '- OK' || echo '- FAIL'`"

.PHONY: check-message
check-message:

.PHONY: check
check: check-message $(foreach dep,$(DEPENDENCIES),require($(dep)))



#----------------------------------------------------------------------

.PHONY: FORCE
FORCE:


%-bootstrap: export BOOTSTRAP=1
%-bootstrap: %
	true


%-bootstrap-clean: export BOOTSTRAP_CLEAN=1
%-bootstrap-clean: %
	true


%: config %/make.sh FORCE
	$*/make.sh


%.config: %/config.example


config.global: config.global.example
	@ [ ! -e "$@" ] \
		&& cat "$<" > "$@" \
		&& $(EDITOR) "$@" \
	|| true



#----------------------------------------------------------------------
# Shorthands...

.PHONY: config
config: config.global


.PHONY: gate
gate: gate-traefik



#----------------------------------------------------------------------

# XXX goal:
# 	- build minimal system
# 		- bootstrap bridge
# 		- gate
# 		- ns
# 	...not yet sure of the best way to do this...
# 	
.PHONY: bootstrap
bootstrap: host-bootstrap gate-bootstrap \
		ns \
		bootstrap-clean

.PHONY: bootstrap-clean
bootstrap-clean: host-bootstrap-clean



#----------------------------------------------------------------------

.PHONY: core
core: config $(CORE_CTs)


.PHONY: minimal
minimal: core $(MINIMAL_CTs)


.PHONY: dev
dev: minimal $(DEV_CTs) 


.PHONY: all
all: minimal $(APP_CTs)



#----------------------------------------------------------------------

.PHONY: clean
clean:
	-rm -rf \
		*/staging \
		*/traefik



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
