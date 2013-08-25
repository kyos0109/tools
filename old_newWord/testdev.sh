#!/bin/bash
cd /var/spool/hylafax/etc
if [ -f config.cfg ]; then
        . config.cfg
else
        echo "Error !!! No Find Config file."
        exit 13
fi

DEVLIST=($(ls /dev/* | grep -i ttyACM | cut -d '/' -f3))

if [ ${#DEVLIST[@]} != $MODEMLINE ]; then
	service dgc restart > /dev/null 2>&1
	until [ ${#DEVLIST[@]} == $MODEMLINE ]
		do
		unset DEVLIST
		DEVLIST=($(ls /dev/* | grep -i ttyACM | cut -d '/' -f3))
		sleep 1
	done
	for ((a=0; a<${#DEVLIST[@]}; a++));
	do
		/usr/local/sbin/faxgetty -D ${DEVLIST[$a]}
	done
	service hylafax restart > /dev/null 2>&1
else
	for ((a=0; a<${#DEVLIST[@]}; a++));
	do
		/usr/local/sbin/faxgetty -D ${DEVLIST[$a]}
	done
	service hylafax restart > /dev/null 2>&1
fi
