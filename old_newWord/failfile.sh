#!/bin/bash
cd /var/spool/hylafax/etc
if [ -f config.cfg ]; then
        . config.cfg
else
        echo "Error !!! No Find Config file."
        exit 13
fi

YD="`date -d\ 1\ days\ ago +%Y%m%d`"
YBACKUPD="$WORKD/backup/$YD"
DATETIME="`date +%Y/%m/%d\ %T`"

if [ -d $YBACKUPD ]; then
	FILELIST=($(ls -al $YBACKUPD | grep -i fax | cut -d ' ' -f12))
else
	exit 0
fi

WHNMAP="`whereis nmap | cut -d ' ' -f2`"
if [ ! -f $WHNMAP  ]; then
        yum install nmap -y
fi

FTPCONNECT="`nmap $FTPSERVER -p 21 | grep -io 'open'`"

if [ $FTPCONNECT == "" ]; then
        for ((i=0; i<3; i++)); do
                if [ $FTPCONNECT == "" ]; then
                echo "`nmap $FTPSERVER -p 21` by test $i" >> $LOGFILE
                sleep 60
                fi
        done
	echo "$DATETIME delete over 1 day file,but cont poll file to ftp." >> $LOGFILE
	rm -rf $YBACKUPD
        exit 13
fi

if [ ${#FILELIST[@]} == "" ]; then
	exit 0
else
	for ((i=0; i<${#FILELIST[@]}; i++));
	do
	cd $YBACKUPD
	ftp -n $FTPSERVER > /dev/null 2>&1 <<EOC
	user $ID $PW
	cd $REMOTED
	put ${FILELIST[$i]}
	bye
EOC
done
	echo "$DATETIME over 1 day file poll ftp ok!!!." >> $LOGFILE
	rm -rf $YBACKUPD
fi
