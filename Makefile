


config.global: config.global.example
	vim "+0r config.global.example" $@


config: config.global


.PHONY: gate
gate: ./gate-traefik
	$</make.sh


.PHONY: ns
ns: 
	$@/make.sh

.PHONY: ssh
ssh: 
	$@/make.sh

.PHONY: wireguard
wireguard: 
	$@/make.sh

.PHONY: syncthing
syncthing: 
	$@/make.sh


.PHONY: all
all: config gate ns ssh wireguard syncthing



