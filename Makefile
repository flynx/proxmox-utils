


config.global: config.global.example
	vim "+0r config.global.example" $<


config: config.global


gate: gate-traefik
	cd $< && ./make.sh


ns: ns
	cd $< && ./make.sh


all: config gate ns



