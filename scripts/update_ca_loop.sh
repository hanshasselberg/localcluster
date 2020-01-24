#!/bin/bash
cur=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')
ports=$($cur/ports.sh -d $1)
x=1
echo found ports: $ports in $1
while true; do 
	# iterate over every port dc
	for port in $ports; do
		$cur/update_ca.sh $port &
	done
	wait
done
