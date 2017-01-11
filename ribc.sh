#!/bin/bash

SCRIPT=$(realpath $0)
DIR=$(dirname $SCRIPT)

# Run a command in the background.
_evalBg() {
	eval "/bin/bash $@" &
	PID1=$!

	sleep 10 &
	PID2=$!

	wait $PID1
	wait $PID2
	echo "Restart complete!"
}

cmd="${DIR}/execute.sh $1";
_evalBg "${cmd}";
