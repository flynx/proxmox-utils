#!/usr/bin/bash
#
# NOTE: re-run this if the IP/PORT change...
#

# get the current IP...
HOST=$(ip addr show dev lan \
	| grep 'inet ' \
	| cut -d ' ' -f 6 \
	| cut -d '/' -f 1)
PORT=5555
ENCRYPTION=aes-256-gcm

USER=shadowsocks
SCRIPT=shadowsocks
CONFIG=shadowsocks.config


# System and dependencies...

if ! which ssserver > /dev/null ; then
	#setup-apkrepos -cf
	# add edge repos...
	sed \
		-e '/v3\.\d*/{p;s|v3\.\d*|edge|}' \
		-i /etc/apk/repositories
	apk update
	apk add shadowsocks-rust
fi

# user...
if ! [ -e /home/$USER ] ; then
	adduser -D -s /sbin/nologin $USER
fi



# Configuration/scripts...

cd /home/$USER


# get/generate password...
if [ -e /home/$USER/$CONFIG ] ; then
	PASSWD=$(cat /home/$USER/$CONFIG \
		| grep password \
		| cut -d '"' -f 4)
else
	PASSWD=$(ssservice genkey -m "$ENCRYPTION")
fi


# /home/$USER/$CONFIG
cat > $CONFIG << EOF
{
	"server": "${HOST}",
	"server_port": ${PORT},
	"password": "${PASSWD}",
	"method": "${ENCRYPTION}"
}
EOF
chown $USER:$USER $CONFIG
chmod 600 $CONFIG


# /home/$USER/$SCRIPT
cat > $SCRIPT << EOF
#!/sbin/openrc-run

command="ssserver"
command_args="-c /home/$USER/$CONFIG"
command_user=$USER

pidfile="/run/\$SVCNAME.pid"
command_background=true

# Debug
#output_log="/home/$USER/\$SVCNAME.log"
#error_log="/home/$USER/\$SVCNAME.err"

depend() {
	need net
}
EOF
chown $USER:$USER $SCRIPT
chmod +x $SCRIPT



# Setup the service...

ln -s /home/$USER/$SCRIPT /etc/init.d/$SCRIPT
if ! [ -e /etc/runlevels/default/$SCRIPT ] ; then
	rc-update add $SCRIPT default
fi
rc-service $SCRIPT restart



# vim:set ts=4 sw=4 :
