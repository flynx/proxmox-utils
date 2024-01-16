#----------------------------------------------------------------------
#
#----------------------------------------------------------------------

INTERFACE := wg0

SERVER_DIR := /etc/wireguard/
SERVER_TPL := templates/server.conf
SERVER_CLIENT_TPL := templates/client.tpl
SERVER_CONF := $(SERVER_DIR)/$(INTERFACE).conf
SERVER_KEY := $(SERVER_DIR)/server_id
SERVER_PUBLIC_KEY := $(SERVER_DIR)/server_id.pub

CLIENT_TPL := templates/client.conf
CLIENT_DIR := $(SERVER_DIR)/clients/

QRCODE ?= 1

ENDPOINT ?= ${ENDPOINT}
ENDPOINT_PORT ?= ${ENDPOINT_PORT}
DNS ?= ${DNS}
CLIENT_IPS ?= ${CLIENT_IPS}
ALLOWED_IPS ?= ${ALLOWED_IPS}



#----------------------------------------------------------------------

%_id:
	@ mkdir -p $$(dirname $@)
	wg genkey 2> /dev/null > $@
	chmod 600 $@


%_id.pub: %_id
	cat $< | wg pubkey > $@


%_ip:
	./getFreeClientIP > $@


# NOTE: the first letter of each pattern is quoted to prevent it from 
# 	being substituted when generating this Makefile from template.
# XXX build this from client files...
$(SERVER_CONF): $(SERVER_TPL) $(SERVER_KEY)
	cat $< \
		| sed \
			-e 's/\$${\ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${\CLIENT_IPS}/$(subst /,\/,$(CLIENT_IPS))/g' \
			-e 's/\$${\SERVER_PRIVATE_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_KEY)")'/g' \
		> "$@"
	chmod 600 $@
	wg-quick up $(INTERFACE) 


.PRECIOUS: %.wg
%.wg: $(CLIENT_TPL) $(SERVER_CLIENT_TPL) \
		%_id %_id.pub %_ip \
		$(SERVER_CONF) $(SERVER_PUBLIC_KEY)
	@ mkdir -p $(shell dirname "$*")
	cat "$<" \
		| sed \
			-e 's/\$${\DNS}/$(DNS)/g' \
			-e 's/\$${\ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${\ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${\ALLOWED_IPS}/$(subst /,\/,$(ALLOWED_IPS))/g' \
			-e 's/\$${\CLIENT_IP}/$(shell cat $*_ip)\/32/g' \
			-e 's/\$${\CLIENT_PRIVATE_KEY}/$(shell sed -e 's/\//\\\//g' "$*_id")/g' \
			-e 's/\$${\SERVER_PUBLIC_KEY}/$(shell sed -e 's/\//\\\//g' "$(SERVER_PUBLIC_KEY)")/g' \
		> "$@"
	cat "$(SERVER_CLIENT_TPL)" \
		| sed \
			-e 's/\$${\CLIENT_IP}/$(shell cat $*_ip)\/32/g' \
			-e 's/\$${\ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${\ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${\CLIENT_PUBLIC_KEY}/$(shell sed -e 's/\//\\\//g' "$*_id.pub")/g' \
			-e 's/\$${\SERVER_PUBLIC_KEY}/$(shell sed -e 's/\//\\\//g' "$(SERVER_PUBLIC_KEY)")/g' \
		>> "$(SERVER_CONF)"


.PHONY: %.show
%.show: %.wg
	@ [ "$(QRCODE)" == "1" ] \
		&& ( echo "# Profile: $*" \
			&& qrencode -t UTF8 -r "$<" )
	@ cat "$<"
	@ echo 


.PHONY: %.client
%.client: $(CLIENT_DIR)/%.wg update $(CLIENT_DIR)/%.show
	@


#----------------------------------------------------------------------

.PHONY: update
update:
	wg syncconf $(INTERFACE) <(wg-quick strip $(INTERFACE))


.PHONY: server
server: $(SERVER_CONF)



#----------------------------------------------------------------------
