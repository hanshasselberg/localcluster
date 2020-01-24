#!/bin/bash
port=${1:-"8500"}
# select random x so that multiple invocations don't overlap
x=$(( ( RANDOM % 1000000 )  + 1 ))
curl -sL localhost:$port/v1/agent/connect/ca/leaf/cert$x | jq -r ".SerialNumber"
