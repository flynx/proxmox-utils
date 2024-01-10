

%.srv:
	$*/make.sh


config.global: config.global.example
	vim "+0r config.global.example" $@


config: config.global


.PHONY: gate
gate: ./gate-traefik
	$</make.sh


.PHONY: ns
ns: ns.srv

.PHONY: ssh
ssh: ssh.srv 

.PHONY: wireguard
wireguard: wireguard.srv 

.PHONY: syncthing
syncthing: syncthing.srv 

.PHONY: nextcloud
nextcloud: nextcloud.srv 

.PHONY: gitea
gitea: gitea.srv


.PHONY: all
all: config gate ns ssh wireguard syncthing nextcloud gitea



