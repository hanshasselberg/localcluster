#!/bin/bash

rm split*.pem;curl http://localhost:19001/config_dump | jq -r '.configs.clusters.dynamicActiveClusters[].cluster.tlsContext.commonTlsContext | .tlsCertificates[].certificateChain.inlineString + .validationContext.trustedCa.inlineString' | awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "split" n+100 ".pem"}'; ls split* | sort -h
