#!/bin/bash
ports=$(./ports.sh -d $1)
x=1
echo found ports: $ports in $1
while true; do 
	echo "{ \"provider\": \"consul\", \"config\": { \"PrivateKey\": \""`openssl ecparam -name prime256v1 -genkey -noout | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\\n/g'`"\" } }" > new.json

	# iterate over every secondary dc
	for port in $ports; do
		x=$((x + 1))
		echo `env CONSUL_HTTP_ADDR=127.0.0.1:$port consul connect ca set-config -config-file new.json` `curl -sL localhost:$port/v1/connect/ca/configuration | jq -r '.ModifyIndex'` &
		curl -sL localhost:$port/v1/agent/connect/ca/leaf/cert$x | jq -r ".SerialNumber" &
	done
	wait
done
