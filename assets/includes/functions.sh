#!/bin/bash

SCRIPT=$(realpath $0)
DIR=$(dirname $SCRIPT)

INIT () {
  ZONE=$1
  MODE=$2

  if [ "$MODE" == "START" ]; then
    START "$ZONE"
  elif [ "$MODE" == "RESTART" ]; then
    STOP "$ZONE"
    sleep 3
    START "$ZONE"
  elif [ "$MODE" == "STOP" ]; then
    STOP "$ZONE"
  elif [ "$MODE" == "INSTALL" ]; then
    INSTALL
  fi
exit
}

START () {
  ZONE=$1
  read_ini "${DIR}/config.ini"
  INI="${INI__ALL_SECTIONS}"

  echo "Starting..."

  mkdir -p "${DIR}/temp/"
  cp "${DIR}/config.ini" "${DIR}/temp/config.ini"

  DOWNLOAD_ZONE_FILES "$ZONE"

  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT
  iptables -A INPUT -i lo -j ACCEPT

  PROCESS_ZONE "$ZONE" "$INI" "START"

  iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A INPUT -p udp -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
  iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
  iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable

  iptables -I INPUT -p tcp --dport 1723 -m state --state NEW -j ACCEPT
  iptables -I INPUT -p gre -j ACCEPT
  iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
  iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -s 192.168.1.0/24 -j TCPMSS --clamp-mss-to-pmtu
  iptables -P FORWARD ACCEPT
}

RESTART () {
  ZONE=$1
  INI=$2

  DOWNLOAD_ZONE_FILES "$ZONE"
  PROCESS_ZONE "$ZONE" "$INI" "RESTART"
}

STOP () {
  ZONE=$1
  read_ini "${DIR}/temp/config.ini"
  INI="${INI__ALL_SECTIONS}"

  echo "Stopping..."

  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -A INPUT -i lo -j ACCEPT

  PROCESS_ZONE "$ZONE" "$INI" "STOP"

  iptables -D INPUT -p icmp --icmp-type 8 -s 0/0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -D INPUT -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -D INPUT -p udp -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -D INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
  iptables -D INPUT -p tcp -j REJECT --reject-with tcp-reset
  iptables -D INPUT -j REJECT --reject-with icmp-proto-unreachable
}

CHANGE_DIR () {
  # If not, create the folder
  if [ ! -d "$1" ]; then
    mkdir -p $1
  fi
  cd $1
}

DOWNLOAD_ZONE_FILES () {
  ZONE=$1

  echo "$ZONE"
  CHANGE_DIR ${DATA_DIR[$ZONE]}

  echo "  Checking if zones have updates."
  $(wget -N ${ZONE_FILES[$ZONE]} -o log)
  LOG=$(cat log | grep 'Saving to')

  if [ ! -z "$LOG" ]; then
    echo "  Updated zones downloaded."
    tar xf all-zones.tar.gz
  else
    echo "  No updates in zones."
  fi
}

PROCESS_ZONE () {
  ZONE=$1
  INI=$2
  INIT=$3

  echo "Processing zone: $ZONE"

  # Loop every section from ini
  for SECTION in $INI; do
    eval "ACTION="'${INI__'${SECTION}'__action}'
    eval "PORTS="'${INI__'${SECTION}'__ports}'

    echo "  $SECTION $ACTION $PORTS"

    if [ "$INIT" == "START" ]; then
      IPTABLES_CHAIN "$ZONE" "$SECTION" "$PORTS" "CREATE"
      PROCESS "$ZONE" "$SECTION" "$ACTION"
    elif [ "$INIT" == "RESTART" ]; then
      IPTABLES_CHAIN "$ZONE" "$SECTION" "$PORTS" "REMOVE"
      IPTABLES_CHAIN "$ZONE" "$SECTION" "$PORTS" "CREATE"
      PROCESS "$ZONE" "$SECTION" "$ACTION"
    else
      IPTABLES_CHAIN "$ZONE" "$SECTION" "$PORTS" "REMOVE"
    fi

    echo
  done
}

PROCESS () {
  ZONE=$1
  SECTION=$2
  ACTION=$3

  if [ "$SECTION" == "all" ]; then
      APPLY "$ZONE" "$SECTION" "$ACTION"
  else
    # Get IPs from zone file
    ZONE_IPS=$(<${SECTION}.zone)

    # Check how many lines the zone file has, so we can create a progress
    LINES=$(cat ${SECTION}.zone | wc -l)

    ROW=1

    # Foreach line, apply the action for this section
    for IP in $ZONE_IPS; do
      PERCENT=$(ROUND 100*$ROW/$LINES 2)
      echo -ne "\r $ROW/$LINES ($PERCENT %)"
      APPLY "$ZONE" "$SECTION" "$ACTION" "$IP"
      ((ROW++))
    done
  fi
}

IPTABLES_CHAIN () {
  ZONE=$1
  SECTION=$2
  PORTS=$3
  CHAIN=$4

  if [ "$CHAIN" == "CREATE" ]; then
    iptables -N RIBC-$ZONE-$SECTION
    iptables -A RIBC-$ZONE-$SECTION -j RETURN
    iptables -I INPUT -p tcp -m multiport --dports $PORTS -j RIBC-$ZONE-$SECTION
  else
    iptables -D INPUT -p tcp -m multiport --dports $PORTS -j RIBC-$ZONE-$SECTION
    iptables -F RIBC-$ZONE-$SECTION
    iptables -X RIBC-$ZONE-$SECTION
  fi
}

APPLY () {
  ZONE=$1
  SECTION=$2
  ACTION=$3
  IP=$4

  if [ "$SECTION" == "all" ]; then
    iptables -I RIBC-$ZONE-$SECTION 1 -j $ACTION
  else
    iptables -I RIBC-$ZONE-$SECTION 1 -s $IP -j $ACTION
  fi
}

ROUND () {
  echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
}

INSTALL () {
  STARTUP_PATH="/etc/init.d/ribc"

  cp "${DIR}/assets/startup.sh" $STARTUP_PATH
  chmod 755 $STARTUP_PATH
  update-rc.d ribc defaults
}
