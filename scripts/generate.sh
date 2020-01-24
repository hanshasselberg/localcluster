#!/bin/bash
x=$(( ( RANDOM % 100000 )  + 1 )); 
ports=`head -300 out.log | grep "dc.-s" | grep -v "dc1-s" | awk '{print $7}'`
echo found ports: $ports
while true; do 

	for i in `seq 10`; do
		# iterate over every secondary dc
		for port in $ports; do
			x=$((x + 1))
			curl -sL localhost:$port/v1/agent/connect/ca/leaf/cert$x | jq -r ".SerialNumber" &
		done
	done
	wait
done
