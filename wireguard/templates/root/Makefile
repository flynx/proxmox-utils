


SERVER_DIR := /etc/wireguard/
SERVER_TPL := templates/wg0.conf
SERVER_CLIENT_TPL := templates/wg0-client.tpl
SERVER_CONF := $(SERVER_DIR)/wg0.conf
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



%_id:
	@ mkdir -p $$(dirname $@)
	wg genkey 2> /dev/null > $@
	chmod 600 $@

%_id.pub: %_id
	cat $< | wg pubkey > $@


# NOTE: the first letter of each pattern is quoted to prevent it from 
# 	being substituted when generating this Makefile from template.
$(SERVER_CONF): $(SERVER_TPL) $(SERVER_KEY)
	cat $< \
		| sed \
			-e 's/\$${\ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${\CLIENT_IPS}/$(subst /,\/,$(CLIENT_IPS))/g' \
			-e 's/\$${\SERVER_PRIVATE_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_KEY)")'/g' \
		> "$@"

%.client: $(CLIENT_TPL) $(SERVER_CLIENT_TPL) \
		$(CLIENT_DIR)/%_id $(CLIENT_DIR)/%_id.pub \
		$(SERVER_CONF) $(SERVER_PUBLIC_KEY)
	@ mkdir -p $(CLIENT_DIR)
	cat "$<" \
		| sed \
			-e 's/\$${\DNS}/$(DNS)/g' \
			-e 's/\$${\ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${\ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${\ALLOWED_IPS}/$(subst /,\/,$(ALLOWED_IPS))/g' \
			-e 's/\$${\CLIENT_IP}/$(shell ./getFreeClientIP)\/32/g' \
			-e 's/\$${\CLIENT_PRIVATE_KEY}/'$$(sed -e 's/\//\\\//g' "$(CLIENT_DIR)/$*_id")'/g' \
			-e 's/\$${\SERVER_PUBLIC_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_PUBLIC_KEY)")'/g' \
		> "$(CLIENT_DIR)/$*.conf"
	ln -s "$(CLIENT_DIR)/$*.conf"
	cat "$(SERVER_CLIENT_TPL)" \
		| sed \
			-e 's/\$${\CLIENT_IP}/$(shell ./getFreeClientIP)\/32/g' \
			-e 's/\$${\ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${\ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${\CLIENT_PUBLIC_KEY}/'$$(sed -e 's/\//\\\//g' "$(CLIENT_DIR)/$*_id.pub")'/g' \
			-e 's/\$${\SERVER_PUBLIC_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_PUBLIC_KEY)")'/g' \
		>> "$(SERVER_CONF)"
	@ [ -z "$$QRCODE" ] \
		|| ( echo "# Profile: $*" \
			&& qrencode -t UTF8 -r "$(CLIENT_DIR)/$*.conf" )



%.qr: %.client
	@ ( echo "# Profile: $*" \
		&& qrencode -t UTF8 -r "$*.conf" )


server: $(SERVER_CONF)



