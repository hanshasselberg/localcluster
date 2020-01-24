#!/bin/bash

exec 4>&2

function errecho() {
  echo "$@" >&4
}

function usage() { 
  echo  "Usage: $0 OPTIONS"
  echo  "  -t type of instance to get ports from: s for server or c for client."
  echo  "  -d datacenter name."
  echo  "  -p port to get, defaults to http. (http|grpc|https)"
  echo  ""
  echo  "Examples:"
  echo  '  `./ports.sh` # will print http ports from clients and servers from all datacenters'
  exit 1
}

while getopts ":d:hp:t:" o; do
  case "${o}" in
    d)
      d=${OPTARG}
      ;;
    p)
      p=${OPTARG}
      ;;
    t)
      t=${OPTARG}
      ;;
    h)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

t=${t:-"[sc]"}
d=${d:-"\\d+"}
p=${p:-"http"}

if [[ "$p" == "http" ]]; then
  i=6
elif [[ "$p" == "grpc" ]]; then
  i=8
elif [[ "$p" == "https" ]]; then
  i=10
else
  i=6
fi

errecho "$p ports in $d"
head -300 $(realpath "$0" | sed 's|\(.*\)/.*|\1|')/../out.log | grep -E "\+ consul.*$d-$t\\d+" | awk "{print \$$i}"
