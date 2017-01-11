#!/bin/sh
### BEGIN INIT INFO
# Provides:          ribc
# Required-Start:    $network $remote_fs
# Required-Stop:     $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Restrict iptables by country
### END INIT INFO

DAEMON=/root/restrict-iptables-by-country/ribc.sh
LOCK=/var/lock/ribc.lock

case "$1" in
	start)
		/bin/bash $DAEMON START
		touch $LOCK
		;;
	stop)
		/bin/bash $DAEMON STOP
		rm $LOCK
		;;
	restart)
		/bin/bash $DAEMON RESTART
		;;
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
esac

exit 0
