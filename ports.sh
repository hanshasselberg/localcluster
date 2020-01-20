#!/bin/bash

function usage() { 
  echo  "Usage: $0 OPTIONS"
  echo  "  -t type of instance to get ports from: s for server or c for client."
  echo  "  -d datacenter name."
  echo  ""
  echo  "Examples:"
  echo  '  `./ports.sh` # will print http ports from clients and servers from all datacenters'
  exit 1
}

while getopts ":d:ht:" o; do
  case "${o}" in
    d)
      d=${OPTARG}
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

head -300 out.log | grep -E "\+ consul.*$d-$t\\d+" | awk '{print $6}'
