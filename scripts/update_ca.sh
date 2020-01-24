#!/bin/bash
port=${1:-"8500"}
echo "{ \"provider\": \"consul\", \"config\": { \"PrivateKey\": \""`openssl ecparam -name prime256v1 -genkey -noout | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\\n/g'`"\" } }" > new.json
echo `env CONSUL_HTTP_ADDR=127.0.0.1:$port consul connect ca set-config -config-file new.json` `curl -sL localhost:$port/v1/connect/ca/configuration | jq -r '.ModifyIndex'`
