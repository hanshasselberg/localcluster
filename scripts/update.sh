#!/bin/bash
ports=$(./ports.sh -d dc1)
echo found ports: $ports
echo "{ \"provider\": \"consul\", \"config\": { \"PrivateKey\": \""`openssl ecparam -name prime256v1 -genkey -noout | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\\n/g'`"\" } }" > new.json

# iterate over every secondary dc
for port in $ports; do
	echo `env CONSUL_HTTP_ADDR=127.0.0.1:$port consul connect ca set-config -config-file new.json` `curl -sL localhost:$port/v1/connect/ca/configuration | jq -r '.ModifyIndex'` &
done
