#!/bin/bash

set -e
set -u
set -o pipefail

rm -f out.log
exec 3>&1
function special_echo() {
  echo "$@" >&3
}

exec &> out.log

usage() { echo "Usage: $0 [-s <string>] [-a <string>] [-l <trace,debug,info,warn,err>] [-n <int>] [-m <int>] [-e <string>]" 1>&2; exit 1; }

while getopts ":s:a:l:n:m:e:" o; do
  case "${o}" in
    s)
      s=${OPTARG}
      ;;
    a)
      a=${OPTARG}
      ;;
    l)
      l=${OPTARG}
      ;;
    n)
      n=${OPTARG}
      ;;
    m)
      m=${OPTARG}
      ;;
    e)
      e=${OPTARG}
      ;;
    ?)
      usage
      ;;
  esac
done

shift $((OPTIND-1))
l=${l:-"info"}
n=${n:-"2"}
m=${m:-"5"}
echo "{}">dummy.json
a=${a:-"dummy.json"}
s=${s:-"dummy.json"}

function startLeader() {
  rm -rf "l" && consul agent -server -bootstrap -data-dir l -bind 127.0.0.1 -node l -log-level $l -config-file $s
}

function startServer() {
  local id="s$1"
  let "server = 9000 + $1"
  let "serf = 10000 + $1"
  let "http = 20000 + $1"
  let "dns = 30000 + $1"
  rm -rf "$id" && consul agent -server -retry-join localhost:8301 -data-dir "$id" -bind 127.0.0.1 -node "$id" -serf-lan-port "$serf" -serf-wan-port -1 -http-port "$http" -dns-port "$dns" -server-port $server -log-level $l -config-file $s
}

function startClient() {
  local id="c$1"
  let "serf = 40000 + $1"
  let "http = 50000 + $1"
  let "dns = 60000 + $1"
  rm -rf "$id" && consul agent -retry-join localhost:8301 -data-dir "$id" -bind 127.0.0.1 -node "$id" -serf-lan-port "$serf" -serf-wan-port -1 -http-port "$http" -dns-port "$dns" -log-level $l -config-file $a
}

function observeCluster() {
  local up='false'
  let "total = 1 + $1 + $2"
  while true; do
    set +e
    count=$(curl -s localhost:8500/v1/agent/members | jq '. | length')
    set -e
    if [ "$count" = "$total" ]; then
      special_echo "cluster is up"
      execWhenClusterReady $e
      return
    fi
    sleep 2
  done
}

function execWhenClusterReady() {
  out=$(./$1)
  special_echo "$out"
}

trap 'killall' INT

killall() {
    trap '' INT TERM          # ignore INT and TERM while shutting down
    special_echo "Shutting down..."   # added double quotes
    kill -TERM 0
    wait
}

set -o xtrace

startLeader &

for i in $(seq $n); do
  startServer $i &
done

for i in $(seq $m); do
  startClient $i &
done

observeCluster $n $m &

cat # wait forever