#!/bin/bash

SCRIPT=$(realpath $0)
DIR=$(dirname $SCRIPT)

source "${DIR}/assets/includes/include.sh"

INIT 'IPV4' $1
