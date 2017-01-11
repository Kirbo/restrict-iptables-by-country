#!/bin/bash

SCRIPT=$(realpath $0)
DIR=$(dirname $SCRIPT)

# Run a command in the background.
_evalBg() {
#    eval "$@" &>/dev/null &disown;
#    eval "/bin/bash $@" &
#	nohup /bin/bash "$@" &
	eval "/bin/bash $@" &
	PID1=$!
	sleep 10 &
	PID2=$!
#	sleep 10
	wait $PID1
	echo "Restart complete!"
#	exit
	wait
	echo "All done"
}

cmd="${DIR}/execute.sh $1";
_evalBg "${cmd}";
