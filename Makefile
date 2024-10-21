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

EDITOR ?= nano


# CTs...
#
MINIMAL_CTs := \
	ssh wireguard 
APP_CTs := \
	syncthing nextcloud
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
	@true


%-bootstrap-clean: export BOOTSTRAP_CLEAN=1
%-bootstrap-clean: %
	@true


%: config %/make.sh FORCE
	$*/make.sh


%.config: %/config.example


config.global: config.global.example
	@ [ ! -e "$@" ] \
		&& cat "$<" > "$@" \
		&& $(EDITOR) "$@" \
	|| true



#----------------------------------------------------------------------
# Bootstrapping...

# Bootstrap stage 1: build basic infrastructure...
.PHONY: bootstrap
bootstrap: \
		host-bootstrap \
		gate-bootstrap ns \
		$(MINIMAL_CTs)
	make bootstrap-clean


# Bootstrap stage 2: reconnect host through the base infrastructure...
.PHONY: bootstrap-clean 
bootstrap-clean: host-bootstrap-clean


# Finalize: reconect admin port/bridge correctly...
.PHONY: _finalize
_finalize: bootstrap-clean gate-bootstrap-clean 
	make host-bootstrap-clean


.PHONY: finalize
finalize:
	###
	### This will break the connection to the server, to continue:
	### - Detach the ADMIN port, 
	### - Connect the WAN port,
	### - $ ssh <user>@<WAN_SSH_IP> 
	###   from there:
	###   $ ssh root@pve
	###   then:
	###   # tmux a
	### - When done this will reboot the system.
	###
	tmux new-session 'make _finalize'



#----------------------------------------------------------------------
# Shorthands...

.PHONY: config
config: config.global


.PHONY: gate
gate: gate-traefik



#----------------------------------------------------------------------

.PHONY: all
all: $(APP_CTs)


.PHONY: dev
dev: $(DEV_CTs) 



#----------------------------------------------------------------------

.PHONY: clean
clean:
	-rm -rf \
		*/staging \
		*/traefik



#----------------------------------------------------------------------
# vim:set ts=4 sw=4 nowrap :
