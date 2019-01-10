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
  special_errecho "Usage: $0 [-s <string>] [-a <string>] [-l <trace,debug,info,warn,err>] [-n <int>] [-m <int>] [-e <string>] [-d <int>]"
  special_errecho "  -a path to config file for agents"
  special_errecho "  -d number of datacenters to spin up and wan-join together"
  special_errecho "  -e path to script to execute after the cluster is up, must be executable"
  special_errecho "  -h show this help"
  special_errecho "  -l log level (defaults to info)"
  special_errecho "  -m number of clients (defaults to 5)"
  special_errecho "  -n number of servers (leader is seperate, defaults to 2)"
  special_errecho "  -p dc prefix (defaults to dc)"
  special_errecho "  -s path to config file for servers"
  special_errecho ""
  special_errecho "Examples:"
  special_errecho '  `./boot.sh` # will boot 1 leader, 2 servers and 5 clients'
  special_errecho '  `./boot.sh -n 4 -m 20` # will boot 1 leader, 4 servers and 20 clients'
  special_errecho '  `./boot.sh -n 4 -m 20 -d 3` # will boot 1 leader, 4 servers and 20 clients each in dc1, dc2, and dc3 wan-joined together.'
  exit 1
}

while getopts ":s:a:l:n:m:e:d:hp:" o; do
  case "${o}" in
    a)
      a=${OPTARG}
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
    h)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

l=${l:-"info"}
n=${n:-"2"}
m=${m:-"5"}
e=${e:-""}
echo "{}">dummy.json
a=${a:-"dummy.json"}
s=${s:-"dummy.json"}
d=${d:-"1"}
p=${p:-"dc"}

function checkIfConsulIsRunningAlready() {
  if pgrep consul; then
    special_echo "consul is already running"
    exit 1
  fi
}

function startLeader() {
  local dc="$p$1"
  local data="$dc-l"
  let "server = 8100 + $1"
  let "serf = 8300 + $1"
  let "http = 8499 + $1"
  let "wan = 8700 + $1"
  local dns="-1"
  rm -rf "$data" 
  special_echo "$dc leader HTTP: 127.0.0.1:$http"
  set -o xtrace
  consul agent -ui -server -bootstrap -data-dir "$data" -bind 127.0.0.1 -node l -serf-lan-port "$serf" -serf-wan-port "$wan" -http-port "$http" -dns-port "$dns" -server-port $server -log-level $l -config-file $s -datacenter $dc -retry-join-wan localhost:8701
}

function startServer() {
  local dc="$p$1"
  local id="s$2"
  local data="$dc-$id"
  let "server = 10000 + $100 + $2"
  let "serf = 20000 + $100 + $2"
  let "wan = 25000 + $100 + $2"
  let "http = 30000 + $100 + $2"
  let "join = 8300 + $1"
  local dns="-1"
  rm -rf "$data"
  set -o xtrace
  consul agent -ui -server -retry-join "localhost:$join" -data-dir "$data" -bind 127.0.0.1 -node "$id" -serf-lan-port "$serf" -serf-wan-port "$wan" -http-port "$http" -dns-port "$dns" -server-port $server -log-level $l -config-file $s -datacenter $dc -retry-join-wan localhost:8701
}

function startClient() {
  local dc="$p$1"
  local id="c$2"
  local data="$dc-$id"
  let "serf = 40000 + $100 + $2"
  let "http = 50000 + $100 + $2"
  let "dns = 60000 + $100 + $2"
  let "join = 8300 + $1"
  rm -rf "$data" 
  set -o xtrace
  consul agent -ui -retry-join "localhost:$join" -data-dir "$data" -bind 127.0.0.1 -node "$id" -serf-lan-port "$serf" -serf-wan-port -1 -http-port "$http" -dns-port "$dns" -log-level $l -config-file $a -datacenter $dc
}

function waitUntilClusterIsUp() {
  local up='false'
  let "total = 1 + $1 + $2"
  for i in $(seq $d); do
    local dc="$p$i"
    while true; do
      set +e
      set +x
      count=$(curl -s "localhost:8500/v1/agent/members?dc=$dc" | jq '. | length')
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

function execWhenClusterReady() {
  if [ -n "${1-}" ]; then
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

for (( i=1; i<=$d; i++ )); do
  startLeader $i &

  for (( j=1; j<=$n; j++ )); do
    startServer $i $j &
  done

  for (( j=1; j<=$m; j++ )); do
    special_echo "start client $i $j"
    startClient $i $j &
  done
done

waitUntilClusterIsUp $n $m

execWhenClusterReady $e

cat # wait forever
