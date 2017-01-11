#!/bin/bash

SCRIPT=$(realpath $0)
DIR=$(dirname $SCRIPT)

source "${DIR}/assets/bash_ini_parser/read_ini.sh"
source "${DIR}/assets/includes/config.sh"
source "${DIR}/assets/includes/functions.sh"
