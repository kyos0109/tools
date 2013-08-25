#!/bin/bash
#test reconnect USB mod
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#test dev/ttyACMx
INITTTYID=10
TTYID=`ls /dev/ttyACM* | sed 's/^.*dev\///g' | sed 's/^.*ttyACM//g' | wc -l`

if [ $INITTTYID != $TTYID ]; then
	rmmod ehci_hcd
	modprobe ehci_hcd > /dev/null 2>&1
fi
