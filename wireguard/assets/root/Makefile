


SERVER_DIR := /etc/wireguard/
SERVER_TPL := templates/wg0.conf
SERVER_CLIENT_TPL := templates/wg0-client.conf
SERVER_CONF := $(SERVER_DIR)/wg0.conf
SERVER_KEY := $(SERVER_DIR)/server_id
SERVER_PUBLIC_KEY := $(SERVER_DIR)/server_id.pub

CLIENT_TPL := templates/client.conf
CLIENT_DIR := $(SERVER_DIR)/clients/

ENDPOINT_PORT := 51820
ENDPOINT := 
CLIENT_IPS := 10.42.0.0/16
DNS := 10.1.1.1


%_id:
	@ mkdir -p $$(dirname $@)
	wg genkey > $@

%_id.pub: %_id
	cat $< | wg pubkey > $@


$(SERVER_CONF): $(SERVER_TPL) $(SERVER_KEY)
	cat $< \
		| sed \
			-e 's/\$${ENDPOINT_PORT}/$(SERVER_PORT)/g' \
			-e 's/\$${CLIENT_IPS}/$(subst /,\/,$(CLIENT_IPS))/g' \
			-e 's/\$${SERVER_PRIVATE_KEY}/'$$(cat "$(SERVER_KEY)" | sed -e 's/\//\\\//')'/g' \
		> "$@"

$(CLIENT_DIR)/%.conf: $(CLIENT_TPL) $(SERVER_CLIENT_TPL) \
		$(CLIENT_DIR)/%_id $(CLIENT_DIR)/%_id.pub \
		$(SERVER_CONF) $(SERVER_PUBLIC_KEY)
	@ mkdir -p $$(dirname $@)
	cat "$<" \
		| sed \
			-e 's/\$${DNS}/$(DNS)/g' \
			-e 's/\$${ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${ALLOWED_IPS}/$(subst /,\/,$(ALLOWED_IPS))/g' \
			-e 's/\$${CLIENT_IP}/$(subst /,\/,$(CLIENT_IP))/g' \
			-e 's/\$${CLIENT_PRIVATE_KEY}/'$$(cat "$(CLIENT_DIR)/$%_id" | sed -e 's/\//\\\//')'/g' \
			-e 's/\$${SERVER_PUBLIC_KEY}/'$$(cat "$(SERVER_PUBLIC_KEY)" | sed -e 's/\//\\\//')'/g' \
		> "$@"
	cat "$(SERVER_CLIENT_TPL)" \
		| sed \
			-e 's/\$${CLIENT_IP}/$(subst /,\/,$(CLIENT_IP))/g' \
			-e 's/\$${ENDPOINT}/$(ENDPOINT)/g' \
			-e 's/\$${ENDPOINT_PORT}/$(ENDPOINT_PORT)/g' \
			-e 's/\$${CLIENT_PUBLIC_KEY}/'$$(cat "$(CLIENT_DIR)/$%_id.pub" | sed -e 's/\//\\\//')'/g' \
			-e 's/\$${SERVER_PUBLIC_KEY}/'$$(cat "$(SERVER_PUBLIC_KEY)" | sed -e 's/\//\\\//')'/g' \
		>> "$(SERVER_CONF)"



server: $(SERVER_CONF)


clients:



