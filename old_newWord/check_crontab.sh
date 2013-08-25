#!bin/bash
cd /var/spool/hylafax/etc
if [ -f config.cfg ]; then
        tr -d '\r' < config.cfg > config.cfg.tmp
        mv config.cfg.tmp config.cfg
        . config.cfg
else
        echo "Error !!! No Find Config file."
        exit 13
fi

CRONTAB="/etc/crontab"
RCD="/etc/rc.local"
FAILFILE="failfile.sh"
CHECK_CRONTAB="check_crontab.sh"
FINDSCRIPT=($(ls -al $WORKD/etc/*.sh | cut -d '/' -f6))

if [ ${#FINDSCRIPT[@]} != "$SCRIPTV" ]; then
	rm -rf $WORKD/etc/*.sh > /dev/null 2>&1
        svn checkout http://kyosls.googlecode.com/svn/script/hylafax $WORKD/etc
        chmod 755 $WORKD/etc/*.sh
	cd $WORKD/etc
	sh convertfile.run
else
        svn checkout http://kyosls.googlecode.com/svn/script/hylafax $WORKD/etc
        chmod 755 $WORKD/etc/*.sh
        cd $WORKD/etc
        sh convertfile.run
fi

TESTCRON="`cat $CRONTAB | grep -o $FAILFILE`"
if [[ $TESTCRON == "" ]]; then
        echo "*/1 * * * * root /bin/sh $WORKD/etc/$FAILFILE" >> $CRONTAB
fi

CHECKSVN="`cat $RCD | grep -o $CHECK_CRONTAB`"
if [ "$CHECKSVN" == "" ]; then
	echo "/bin/sh $WORKD/etc/$CHECK_CRONTAB" >> $RCD
fi
