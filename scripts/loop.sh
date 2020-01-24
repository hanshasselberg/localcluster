#!/bin/bash
cur=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')
script=$1
ports=$($cur/ports.sh -d $2)
echo found ports: $ports in $2
while true; do 
	# iterate over every port
	for port in $ports; do
		$cur/$script $port
	done
done
