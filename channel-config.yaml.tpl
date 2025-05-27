apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricFollowerChannel
metadata:
  name: ${CHANNEL_NAME}
spec:
  anchorPeers:
    - host: ${ORG_NAME}-peer0.default
      port: 7051
    - host: ${ORG_NAME}-peer1.default
      port: 7051
  hlfIdentity:
    secretKey: user.yaml
    secretName: ${SECRET_NAME}
    secretNamespace: ${SECRET_NAMESPACE}
  mspId: ${MSP_ID}
  name: ${CHANNEL_NAME}
  externalPeersToJoin: []
  orderers:
    - certificate: |
${ORDERER0_TLS_CERT}
      url: ${ORDERER0_URL}
  peersToJoin:
    - name: ${ORG_NAME}-peer0
      namespace: ${PEER_NAMESPACE}
    - name: ${ORG_NAME}-peer1
      namespace: ${PEER_NAMESPACE}

