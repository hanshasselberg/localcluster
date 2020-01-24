#!/bin/bash
cur=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')
script=$1
ports=$($cur/ports.sh -d $2)
x=1
echo found ports: $ports in $1
while true; do 
	# iterate over every port dc
	for port in $ports; do
		$cur/$script $port &
	done
	wait
done
