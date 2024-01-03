


config.global: config.global.example
	vim "+0r config.global.example" $<


config: config.global


gate: gate-traefik
	$</make.sh


ns: ns
	$</make.sh


all: config gate ns



