#!/bin/bash
SyncDIR="/home/service/resources"
Find_InotifyPID="`ps ax | grep -i inotify | grep -v grep | cut -d ' ' -f2`"

start (){
        if [ "$Find_InotifyPID" != "" ]; then
                echo "Mirror Still Running"
                exit 1
        else
                ( inotifywait -mrq -e create,move,delete,modify $SyncDIR \
                | while read DIR ACT FILE
                        do unison > /dev/null 2>&1
                done & )
        fi
        }

stop (){
        if [ "$Find_InotifyPID" == "" ]; then
                echo "Mirror File Not Running"
        else
                kill $Find_InotifyPID
                echo "Mirror File Stop"
        fi
        }

status (){
        if [ "$Find_InotifyPID" == "" ]; then
                echo "Mirror File Stop"
        else
                echo "Mirror File Running"
        fi
        }

case $1 in
 start)
        start
        echo "Running File Mirror..."
        ;;

 stop)
        stop
        ;;

 status)
        status
        ;;

 restart)
        stop
        start
        ;;

 *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;

esac