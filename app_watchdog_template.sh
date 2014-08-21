#!/bin/sh
#set -x


#***************************************************
#APP specific Configurations
APPNAME=app
INTERVAL=30     #Interval between status checks
LOCKFILE=/var/run/$APPNAME.pid	#monitor app if this files exists.
INIT_SCRIPT=/etc/init.d/$APPNAME
WATCHDOGNAME=$APPNAME_watchdog
#***************************************************

#
# $WATCHDOGNAME:   This starts and stops the $APPNAME WatchDog
#
# chkconfig: 345 99 05
# description: Ensures $APPNAME is running
#
# processname: $WATCHDOGNAME
#

#import standard rh funcions
if [ -f /etc/init.d/functions ]
then
        . /etc/init.d/functions
fi
PATH=/bin:/sbin:/usr/bin:/usr/sbin
MYNAME=`basename $0`




start()
{
		#relaunch myself in monitor mode
        daemon $0 monitor 2>&1 >/dev/null &
		RETVAL=0
}
monitor()
{
	#infinite loop until stop is called
	while [ 1 -eq 1 ]
	do
		#no restarting if there is no lockfile, this ensures there are no unsolicited restarts
		#it also means that the application must delete its lockfile when stop is called.		
		if [ -f $LOCKFILE ]
		then
			$INIT_SCRIPT status 2>&1 >/dev/null
			STATUS=$?
			if [ $STATUS -gt 0 ]
			then
					logger -t $WATCHDOGNAME "Status returned ERROR!"
					doRestart
			fi
		fi
		sleep $INTERVAL
	done
}
stop()
{
	#pgrep could also be used by sometimes it acts up...
	my_pids=`ps ax|awk '/$MYNAME/ {print $1}'`	
	kill -9 $my_pids
	RETVAL=0

}
status()
{
	echo "OK"
	RETVAL=0
}


doRestart()
{
	logger -t $WATCHDOGNAME "Stopping $APPNAME..."
	$INIT_SCRIPT stop 2>&1 >/dev/null
	logger -t $WATCHDOGNAME "$APPNAME stopped"
	
	sleep 5
	
	logger -t $WATCHDOGNAME "Starting $APPNAME"
	$INIT_SCRIPT start 2>&1 >/dev/null
	logger -t $WATCHDOGNAME "$APPNAME started"

}


case "$1" in
	status)
		status
		RETVAL=$?
		;;
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		stop
		sleep 2
		start
		RETVAL=$?
		;;
	monitor)
		monitor
		;;
	*)
		echo $"Usage: $0 {status|start|stop|restart}"
		exit 1
esac

exit $RETVAL
