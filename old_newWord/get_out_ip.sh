#!/bin/bash		
	LYNX="/usr/bin/lynx"		
	if [ ! -f $LYNX ]; then		
	        yum install lynx -y		
	fi
lynx -dump http://checkip.dyndns.org/ | grep [0-9] | cut -d ' ' -f7
wget -q -O - http://checkip.dyndns.org/ | cut -d ' ' -f6 | cut -d '<' -f1