apiVersion: hlf.kungfusoftware.es/v1alpha1
kind: FabricMainChannel
metadata:
  name: esg-channel
spec:
  name: esg-channel
  adminOrdererOrganizations:
    - mspID: OrdererMSP
  adminPeerOrganizations:
    - mspID: Tier1MSP
    - mspID: Tier2MSP
    - mspID: Tier3MSP
  channelConfig:
    application:
      acls: null
      capabilities:
        - V2_5
      policies: null
    capabilities:
      - V3_0
    orderer:
      batchSize:
        absoluteMaxBytes: 1048576
        maxMessageCount: 100
        preferredMaxBytes: 524288
      batchTimeout: 2s
      capabilities:
        - V2_0
      smartBFT:
        request_batch_max_count: 100
        request_batch_max_bytes: 10485760
        request_batch_max_interval: "50ms"
        incoming_message_buffer_size: 200
        request_pool_size: 100000
        request_forward_timeout: "2s"
        request_complain_timeout: "20s"
        request_auto_remove_timeout: "3m"
        view_change_resend_interval: "5s"
        view_change_timeout: "20s"
        leader_heartbeat_timeout: "1m0s"
        leader_heartbeat_count: 10
        collect_timeout: "1s"
        sync_on_start: true
        speed_up_view_change: false
        leader_rotation: 2
        decisions_per_leader: 3
        request_max_bytes: 0

      consenterMapping:
      - host: orderer0-ord.localho.st
        port: 443
        id: 1
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER0_TLS_CERT}
        server_tls_cert: |
${ORDERER0_TLS_CERT}
        identity: |
${ORDERER0_SIGN_CERT}

      - host: orderer1-ord.localho.st
        port: 443
        id: 2
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER1_TLS_CERT}
        server_tls_cert: |
${ORDERER1_TLS_CERT}
        identity: |
${ORDERER1_SIGN_CERT}

      - host: orderer2-ord.localho.st
        port: 443
        id: 3
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER2_TLS_CERT}
        server_tls_cert: |
${ORDERER2_TLS_CERT}
        identity: |
${ORDERER2_SIGN_CERT}

      - host: orderer3-ord.localho.st
        port: 443
        id: 4
        msp_id: OrdererMSP
        client_tls_cert: |
${ORDERER3_TLS_CERT}
        server_tls_cert: |
${ORDERER3_TLS_CERT}
        identity: |
${ORDERER3_SIGN_CERT}

      ordererType: BFT
      policies: null
      state: STATE_NORMAL
    policies: null
  externalOrdererOrganizations: []
  peerOrganizations:
    - mspID: Tier1MSP
      caName: "tier1-ca"
      caNamespace: "default"
    - mspID: Tier2MSP
      caName: "tier2-ca"
      caNamespace: "default"
    - mspID: Tier3MSP
      caName: "tier3-ca"
      caNamespace: "default"
  identities:
    OrdererMSP:
      secretKey: user.yaml
      secretName: orderer-admin-tls
      secretNamespace: default
    OrdererMSP-sign:
      secretKey: user.yaml
      secretName: orderer-admin-sign
      secretNamespace: default
    Tier1MSP:
      secretKey: user.yaml
      secretName: tier1-admin
      secretNamespace: default
    Tier2MSP:
      secretKey: user.yaml
      secretName: tier2-admin
      secretNamespace: default
    Tier3MSP:
      secretKey: user.yaml
      secretName: tier3-admin
      secretNamespace: default
  externalPeerOrganizations: []
  ordererOrganizations:
    - caName: "ord-ca"
      caNamespace: "default"
      externalOrderersToJoin:
        - host: ord-node1
          port: 7053
        - host: ord-node2
          port: 7053
        - host: ord-node3
          port: 7053
        - host: ord-node4
          port: 7053
      mspID: OrdererMSP
      ordererEndpoints:
        - orderer0-ord.localho.st:443
        - orderer1-ord.localho.st:443
        - orderer2-ord.localho.st:443
        - orderer3-ord.localho.st:443
      orderersToJoin: []
  orderers:
    - host: ord-node1
      port: 7050
      tlsCert: |
${ORDERER0_TLS_CERT}
    - host: ord-node2
      port: 7050
      tlsCert: |-
${ORDERER1_TLS_CERT}
    - host: ord-node3
      port: 7050
      tlsCert: |-
${ORDERER2_TLS_CERT}
    - host: ord-node4
      port: 7050
      tlsCert: |-
${ORDERER3_TLS_CERT}
