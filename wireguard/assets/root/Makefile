


SERVER_DIR := /etc/wireguard/
SERVER_TPL := templates/wg0.conf
SERVER_CLIENT_TPL := templates/wg0-client.tpl
SERVER_CONF := $(SERVER_DIR)/wg0.conf
SERVER_KEY := $(SERVER_DIR)/server_id
SERVER_PUBLIC_KEY := $(SERVER_DIR)/server_id.pub

CLIENT_TPL := templates/client.conf
CLIENT_DIR := $(SERVER_DIR)/clients/

CLIENT_IPS ?= 10.42.0.0/16
ENDPOINT_PORT ?= 51820
ENDPOINT ?= 1.2.3.4

# XXX need to generate this...
CLIENT_IP ?= 10.42.0.1/32
DNS ?= 10.1.1.1
ALLOWED_IPS ?= 0.0.0.0/0


%_id:
	@ mkdir -p $$(dirname $@)
	wg genkey 2> /dev/null > $@
	chmod 600 $@

%_id.pub: %_id
	cat $< | wg pubkey > $@


$(SERVER_CONF): $(SERVER_TPL) $(SERVER_KEY)
	cat $< \
		| sed \
			-e 's/\$${ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${CLIENT_IPS}/$(subst /,\/,$(CLIENT_IPS))/g' \
			-e 's/\$${SERVER_PRIVATE_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_KEY)")'/g' \
		> "$@"

%.client: $(CLIENT_TPL) $(SERVER_CLIENT_TPL) \
		$(CLIENT_DIR)/%_id $(CLIENT_DIR)/%_id.pub \
		$(SERVER_CONF) $(SERVER_PUBLIC_KEY)
	@ mkdir -p $(CLIENT_DIR)
	cat "$<" \
		| sed \
			-e 's/\$${DNS}/$(patsubst /%,,$(DNS))/g' \
			-e 's/\$${ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${ALLOWED_IPS}/$(subst /,\/,$(ALLOWED_IPS))/g' \
			-e 's/\$${CLIENT_IP}/$(subst /,\/,$(CLIENT_IP))/g' \
			-e 's/\$${CLIENT_PRIVATE_KEY}/'$$(sed -e 's/\//\\\//g' "$(CLIENT_DIR)/$*_id")'/g' \
			-e 's/\$${SERVER_PUBLIC_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_PUBLIC_KEY)")'/g' \
		> "$(CLIENT_DIR)/$*.conf"
	cat "$(SERVER_CLIENT_TPL)" \
		| sed \
			-e 's/\$${CLIENT_IP}/$(subst /,\/,$(CLIENT_IP))/g' \
			-e 's/\$${ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${CLIENT_PUBLIC_KEY}/'$$(sed -e 's/\//\\\//g' "$(CLIENT_DIR)/$*_id.pub")'/g' \
			-e 's/\$${SERVER_PUBLIC_KEY}/'$$(sed -e 's/\//\\\//g' "$(SERVER_PUBLIC_KEY)")'/g' \
		>> "$(SERVER_CONF)"



server: $(SERVER_CONF)



