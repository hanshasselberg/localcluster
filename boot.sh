#!/bin/bash

set -e
set -u
set -o pipefail

rm -f out.log
exec 3>&1
exec 4>&2

function special_echo() {
  echo "$@" >&3
}

function special_errecho() {
  echo "$@" >&4
}

exec &> out.log

function usage() { 
  special_errecho "Usage: $0 OPTIONS"
  special_errecho "  -a path to config file for agents"
  special_errecho "  -b path to script to execute before we start consul"
  special_errecho "  -c domain"
  special_errecho "  -d number of datacenters to spin up and wan-join together"
  special_errecho "  -e path to script to execute after the cluster is up, must be executable"
  special_errecho "  -h show this help"
  special_errecho "  -l log level (defaults to info)"
  special_errecho "  -m number of clients (defaults to 5)"
  special_errecho "  -n number of servers (defaults to 3)"
  special_errecho "  -p dc prefix (defaults to dc)"
  special_errecho "  -s path to config file for servers"
  special_errecho "  -w no wan-join"
  special_errecho ""
  special_errecho "Examples:"
  special_errecho '  `./boot.sh` # will boot 3 servers and 5 clients'
  special_errecho '  `./boot.sh -n 5 -m 20` # will boot 5 servers and 20 clients'
  special_errecho '  `./boot.sh -n 5 -m 20 -d 3` # will boot 5 servers and 20 clients each in dc1, dc2, and dc3 wan-joined together.'
  exit 1
}

while getopts ":a:b:c:d:e:hl:m:n:p:s:w" o; do
  case "${o}" in
    a)
      a=${OPTARG}
      ;;
    b)
      b=${OPTARG}
      ;;
    c)
      c=${OPTARG}
      ;;
    d)
      d=${OPTARG}
      ;;
    e)
      e=${OPTARG}
      ;;
    l)
      l=${OPTARG}
      ;;
    m)
      m=${OPTARG}
      ;;
    n)
      n=${OPTARG}
      ;;
    p)
      p=${OPTARG}
      ;;
    s)
      s=${OPTARG}
      ;;
    w)
      w=1
      ;;
    h)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

l=${l:-"info"}
b=${b:-""}
c=${c:-"consul"}
n=${n:-"3"}
m=${m:-"5"}
e=${e:-""}
echo "{}">dummy.json
d=${d:-"1"}
p=${p:-"dc"}

portFile="$TMPDIR"localclusterLastUsedPort
lockFile="$TMPDIR"localclusterLock
echo 9999 > $portFile

function clientConfig() {
  if [ -n "${a-}" ]; then
    echo $a
    return
  fi
  local dc="$1"
  if [ -f "./client_$dc.json" ]; then
    echo "client_$dc.json"
    return
  fi
  if [ -f "./client.json" ]; then
    echo "client.json"
    return
  fi
  echo "dummy.json"
}

function serverConfig() {
  if [ -n "${s-}" ]; then
    echo $s
    return
  fi
  local dc="$1"
  if [ -f "./server_$dc.json" ]; then
    echo "server_$dc.json"
    return
  fi
  if [ -f "./server.json" ]; then
    echo "server.json"
    return
  fi
  echo "dummy.json"
}

function checkIfConsulIsRunningAlready() {
  if pgrep consul; then
    special_echo "consul is already running"
    exit 1
  fi
}

function knownServerPort() {
  let "port = 8100 + $1"
  echo $port
}

function joinPort() {
  let "port = 8300 + $1"
  echo $port
}

function freePort() {
  ./incr.pl "$lockFile" "$portFile"
}

function startWellKnownServer() {
  local dc="$p$1"
  local id="s1"
  local data="$dc-$id"
  local server=$(knownServerPort $1)
  local serf=$(joinPort $1)
  let "http = 8499 + $1"
  let "wan = 8700 + $1"
  local dns="-1"
  local config=$(serverConfig $dc)

  rm -rf "$data"
  special_echo "$dc well known server HTTP: 127.0.0.1:$http"
  set -o xtrace
  if [ -n "${w:-""}" ]; then
	  consul agent -ui -http-port "$http" -grpc-port $(freePort) -https-port $(freePort) -server -bootstrap-expect $n -data-dir "$data" -bind 127.0.0.1 -node $id -serf-lan-port "$serf" -serf-wan-port "$wan" -dns-port "$dns" -server-port $server -log-level $l -config-file $config -datacenter $dc -domain $c
  else
	  consul agent -ui -http-port "$http" -grpc-port $(freePort) -https-port $(freePort) -server -bootstrap-expect $n -data-dir "$data" -bind 127.0.0.1 -node $id -serf-lan-port "$serf" -serf-wan-port "$wan" -dns-port "$dns" -server-port $server -log-level $l -config-file $config -datacenter $dc -domain $c -retry-join-wan "127.0.0.1:8701"
  fi
}

function startServer() {
  local dc="$p$1"
  local id="s$2"
  local data="$dc-$id"
  local join=$(joinPort $1)
  local config=$(serverConfig $dc)

  rm -rf "$data"
  set -o xtrace
  if [ -n "${w:-""}" ]; then
	  consul agent -ui -http-port $(freePort) -grpc-port $(freePort) -https-port $(freePort) -server -bootstrap-expect $n -retry-join "127.0.0.1:$join" -data-dir "$data" -bind 127.0.0.1 -node "$id" -serf-lan-port $(freePort) -serf-wan-port $(freePort) -dns-port $(freePort) -server-port $(freePort) -log-level $l -config-file $config -datacenter $dc -domain $c
  else
	  consul agent -ui -http-port $(freePort) -grpc-port $(freePort) -https-port $(freePort) -server -bootstrap-expect $n -retry-join "127.0.0.1:$join" -data-dir "$data" -bind 127.0.0.1 -node "$id" -serf-lan-port $(freePort) -serf-wan-port $(freePort) -dns-port $(freePort) -server-port $(freePort) -log-level $l -config-file $config -datacenter $dc -domain $c -retry-join-wan "127.0.0.1:8701"
  fi
}

function startClient() {
  local dc="$p$1"
  local id="c$2"
  local data="$dc-$id"
  local knownServer=$(knownServerPort $1)
  local serf=$(freePort)
  local http=$(freePort)
  local dns=$(freePort)
  local join=$(joinPort $1)
  local config=$(clientConfig $dc)
  rm -rf "$data"
  set -o xtrace
  consul agent -ui -http-port $(freePort) -grpc-port $(freePort) -https-port $(freePort) -retry-join "127.0.0.1:$join" -data-dir "$data" -bind 127.0.0.1 -node "$id" -serf-lan-port $(freePort) -serf-wan-port -1 -dns-port $(freePort) -log-level $l -config-file $config -datacenter $dc -domain $c -server-port $knownServer
}

function waitUntilClusterIsUp() {
  local up='false'
  let "total = $1 + $2"
  for i in $(seq $d); do
    local dc="$p$i"
    while true; do
      set +e
      count=$(curl -s "127.0.0.1:8500/v1/agent/members?dc=$dc" | jq '. | length')
      set -e
      if [ "$count" = "$total" ]; then
        special_echo "$dc is up"
        break
      fi
      sleep 2
    done
  done
  special_echo "cluster is up"
}

function execBefore() {
  if [ -n "${1-}" ]; then
    special_echo "running $1"
    set +e
    out=$($1)
    set -e
    special_echo "$out"
  fi
}

function execWhenClusterReady() {
  if [ -n "${1-}" ]; then
    special_echo "running $1"
    set +e
    out=$($1)
    set -e
    special_echo "$out"
  fi
}

trap 'killall' INT

killall() {
  # ignore INT and TERM while shutting down
  trap '' INT TERM
  special_echo "Shutting down..."
  kill -TERM 0
  wait
}

checkIfConsulIsRunningAlready

execBefore $b

instanceCounter=0
for (( i=1; i<=$d; i++ )); do
  dc=$p$i
  special_echo "$dc server config: $(serverConfig "$dc")"
  special_echo "$dc client config: $(clientConfig "$dc")"
  startWellKnownServer $i &
  for (( j=2; j<=$n; j++ )); do
    startServer $i $j $instanceCounter &
    ((instanceCounter++))
  done

  for (( j=1; j<=$m; j++ )); do
    startClient $i $j $instanceCounter &
    ((instanceCounter++))
  done
done

waitUntilClusterIsUp $n $m

execWhenClusterReady $e

cat # wait forever
