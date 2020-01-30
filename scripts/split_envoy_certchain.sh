#!/bin/bash

rm -f leaf.pem root.pem intermediate*.pem
curl -s http://localhost:19001/config_dump | jq -r '.configs.clusters.dynamicActiveClusters[].cluster.tlsContext.commonTlsContext.tlsCertificates[].certificateChain.inlineString' 2> /dev/null | awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "intermediate" n+100 ".pem"}'
curl -s http://localhost:19001/config_dump | jq -r '.configs.clusters.dynamicActiveClusters[].cluster.tlsContext.commonTlsContext.validationContext.trustedCa.inlineString' > root.pem
mv intermediate100.pem leaf.pem
ls intermediate*.pem | tail -1 | xargs rm # delete empty file
echo "all verify    " $(openssl verify -verbose -CAfile <(cat intermediate*.pem root.pem) leaf.pem)
echo "latest verify " $(openssl verify -verbose -CAfile <(cat $(ls intermediate*.pem | tail -1) root.pem) leaf.pem)
echo "latest" $(openssl x509 -noout -text -in $(ls intermediate*.pem | tail -1) | grep 'Not After')
ls leaf.pem intermediate*.pem root.pem
