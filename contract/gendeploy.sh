cat << EOF > "chaincode-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${CHAINCODE_LABEL}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${CHAINCODE_LABEL}
  template:
    metadata:
      labels:
        app: ${CHAINCODE_LABEL}
    spec:
      containers:
        - name: chaincode
          image: your-username/chaincode:latest
          ports:
            - containerPort: 7052
          env:
            - name: CORE_CHAINCODE_ID_NAME
              value: "${CHAINCODE_NAME}:${VERSION}"
            - name: CORE_PEER_ADDRESS
              value: "org1-peer0.default:7051" 
            - name: CORE_PEER_CHAINCODELISTENADDRESS
              value: "0.0.0.0:7052"  # Listen port for chaincode
---
apiVersion: v1
kind: Service
metadata:
  name: ${CHAINCODE_LABEL}
spec:
  ports:
    - port: 7052
      targetPort: 7052
  selector:
    app: ${CHAINCODE_LABEL}
EOF
