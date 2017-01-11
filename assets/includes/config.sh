#!/bin/bash

SCRIPT=$(realpath $0)
DIR=$(dirname $SCRIPT)

declare -A ZONE_FILES
ZONE_FILES=(
  [IPV4]='http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz'
  [IPV6]='http://www.ipdeny.com/ipv6/ipaddresses/blocks/ipv6-all-zones.tar.gz'
)


declare -A DATA_DIR
DATA_DIR=(
  ['IPV4']="${DIR}/assets/countries/ipv4"
  ['IPV6']="${DIR}/assets/countries/ipv6"
)
