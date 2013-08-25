#v1.3
#ftp upload file

#load config
cd /var/spool/hylafax/etc
if [ -f config.cfg ]; then
	. config.cfg
else
	echo "Error !!! No Find Config file."
	exit 13
fi

if [ ! -f $LOGFILE ]; then
 touch $LOGFILE
fi

#fail file move backup
movefile() {
        BACKUPDIR="$WORKD/backup/`date +%Y%m%d`"
        if [ ! -d $BACKUPDIR ]; then
                mkdir -p $BACKUPDIR
        fi
        cd $WORKD/recvq
        mv $FAXFILENAME $BACKUPDIR
}

# test network
ping 168.95.1.1 -n -c 2 -W 2 &> /dev/null && TNET=0 || TNET=1
ping 8.8.8.8 -n -c 2 -W 2 &> /dev/null && TNET1=0 || TNET1=1
if [ $TNET != 0 ] && [ $TNET1 != 0 ]; then
	echo "$DATETIME Network is Fail." >> $LOGFILE
	movefile
	exit 13
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
	movefile
	exit 13
fi

cd $WORKD
/usr/bin/ftp -n $FTPSERVER > $WORKD/recvq/$FILESIZE 2>&1 <<EOC
user    $ID     $PW
binary
cd $REMOTED
put $FILE $FAXFILENAME
ls $FAXFILENAME
bye
EOC

cd $WORKD/recvq
REMOTESIZE="`cat $FILESIZE | grep -i fax | awk '{print $5}'`"
LOCALSIZE="`ls -al $FAXFILENAME |  grep -i fax | awk '{print $5}'`"
REMOTEFILENAME="`cat $FILESIZE | grep -i fax | awk '{print $9}' | sed 's/.tif*$//g'`"
LOCALFILENAME="`ls -al $FAXFILENAME |  grep -i fax | awk '{print $9}'| sed 's/.tif*$//g'`"

ftpupload() {
NOWD="`/bin/pwd`"
if [ $NOWD != $WORKD ] || [ $NOWD != $WORKD/ ]; then
	cd $WORKD
fi
/usr/bin/ftp -n $FTPSERVER > $WORKD/log/error1.log 2>&1 <<EOC
user  $ID      $PW
binary
cd $REMOTED
delete $FAXFILENAME
put $FILE $FAXFILENAME
bye
EOC
}

check_file() {
if [ $REMOTESIZE != $LOCALSIZE ]; then
	echo "$DATETIME $REMOTESIZE is Different" >> $LOGFILE
else
        echo "$DATETIME ftp upload $FAXFILENAME done." >> $LOGFILE
fi

if [ $REMOTEFILENAME != $LOCALFILENAME ]; then
	echo "$DATETIME $REMOTEFILENAME is Different" >> $LOGFILE
else
	echo "$DATETIME ftp upload Comparison $FAXFILENAME done." >> $LOGFILE
fi
}

#檢查檔案錯誤時,重覆執行校驗
if [ $REMOTESIZE != $LOCALSIZE ] || [ $REMOTEFILENAME != $LOCALFILENAME ]; then
	for ((b=0; b<3; b++));
	do
		if [ $REMOTESIZE != $LOCALSIZE ] || [ $REMOTEFILENAME != $LOCALFILENAME ]; then
			echo "`cat $FILESIZE`" >> $WORKD/log/error1.log
			ftpupload
		        check_file
			echo "$DATETIME $FAXFILENAME dont much trying poll file to ftp." >> $LOGFILE
			sleep 60
		else
			rm -rf $FILESIZE
			rm -rf $FAXFILENAME
		fi
	movefile
	done
else
	rm -rf $FILESIZE
	rm -rf $FAXFILENAME
fi
