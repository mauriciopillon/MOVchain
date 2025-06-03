#!/bin/bash
set -euo pipefail

# ========== COLOR OUTPUT ==========
SUCCESS_COLOR='\033[0;32m'
WARNING_COLOR='\033[0;33m'
INFO_COLOR='\033[0;34m'
ERROR_COLOR='\033[0;31m'
NC='\033[0m' # No Color

info() {
  printf "\n${INFO_COLOR}$1${NC}\n"
}

# ========== CONFIG ==========
ISTIO_VERSION="1.20.0"
HLF_OPERATOR_VERSION="1.11.0-beta3"
PEER_IMAGE="hyperledger/fabric-peer"
PEER_VERSION="3.0.0-preview"
ORDERER_IMAGE="hyperledger/fabric-orderer"
ORDERER_VERSION="3.0.0-preview"
CA_IMAGE="hyperledger/fabric-ca"
CA_VERSION="1.5.7"
STORAGE_CLASS="standard"

export PATH="$PATH:$PWD/istio-${ISTIO_VERSION}/bin"

# ========== FUNCTIONS ==========

wait_for_running() {
  local resource=$1
  sleep 30
  kubectl wait --timeout=240s --for=condition=Running "$resource" --all
  sleep 5
}

create_ca() {
  local name=$1
  local hosts=$2
  kubectl hlf ca create \
    --image=$CA_IMAGE --version=$CA_VERSION --storage-class=$STORAGE_CLASS \
    --capacity=1Gi --name=$name --enroll-id=enroll --enroll-pw=enrollpw \
    --hosts=$hosts --istio-port=443
}

register_user() {
  local ca_name=$1 user=$2 secret=$3 type=$4 mspid=$5
  kubectl hlf ca register \
    --name=$ca_name --user=$user --secret=$secret --type=$type \
    --enroll-id=enroll --enroll-secret=enrollpw --mspid=$mspid
}

create_peer() {
  local name=$1 host=$2 org=$3
  local msp_org="$(tr '[:lower:]' '[:upper:]' <<< ${org:0:1})${org:1}"

  kubectl hlf peer create --statedb=leveldb \
    --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$STORAGE_CLASS \
    --enroll-id=peer --enroll-pw=peerpw --capacity=5Gi \
    --name=$name --mspid=${msp_org}MSP --ca-name=${org}-ca.default --hosts=$host --istio-port=443
}

create_orderer() {
  local name=$1 host=$2 admin_host=$3
  kubectl hlf ordnode create --image=$ORDERER_IMAGE --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS --enroll-id=orderer --mspid=OrdererMSP \
    --enroll-pw=ordererpw --capacity=2Gi --name=$name --ca-name=ord-ca.default \
    --hosts=$host --admin-hosts=$admin_host --istio-port=443
}

create_identity() {
  local name=$1 ca_name=$2 ca_type=$3 mspid=$4 enroll_id=$5 secret=$6
  kubectl hlf identity create --name=$name --namespace default \
    --ca-name=$ca_name --ca-namespace default \
    --ca=$ca_type --mspid=$mspid --enroll-id=$enroll_id --enroll-secret=$secret
}

# ========== SCRIPT START ==========

#info "Creating cluster..."
#kind delete cluster --name kind || true
#kind create cluster --config=./kind-config.yaml
#
#info "Installing Istio in k8s cluster..."
#kubectl create namespace istio-system || true
#istioctl operator init
#kubectl apply -f ./istio-config.yaml
#kubectl apply -f ./istio-configmap.yaml
#
#info "Installing HLF operator..."
#helm repo add kfs https://kfsoftware.github.io/hlf-helm-charts --force-update
#helm upgrade --install hlf-operator --version=$HLF_OPERATOR_VERSION -- kfs/hlf-operator
#
## ========== TIER 1 CA + PEERS ==========
#
#info "Creating Tier 1 CA..."
#create_ca "tier1-ca" "tier1-ca.localho.st"
#wait_for_running fabriccas.hlf.kungfusoftware.es
#
#info "Testing Tier 1 CA..."
#curl -k https://tier1-ca.localho.st:443/cainfo
#
#info "Registering peer identity..."
#register_user "tier1-ca" "peer" "peerpw" "peer" "Tier1MSP"
#
#info "Deploying Tier 1 peers..."
#create_peer "montadora" "montadora.localho.st" "tier1"
#wait_for_running fabricpeers.hlf.kungfusoftware.es
#
## ========== TIER 2 CA + PEERS ==========
#
#info "Creating Tier 2 CA..."
#create_ca "tier2-ca" "tier2-ca.localho.st"
#wait_for_running fabriccas.hlf.kungfusoftware.es
#
#info "Testing Tier 2 CA..."
#curl -k https://tier2-ca.localho.st:443/cainfo
#
#info "Registering peer identity..."
#register_user "tier2-ca" "peer" "peerpw" "peer" "Tier2MSP"
#
#info "Deploying Tier 2 peers..."
#create_peer "vendedor-pneu" "vendedor-pneu.localho.st" "tier2"
#wait_for_running fabricpeers.hlf.kungfusoftware.es
#
## ========== TIER 3 CA + PEERS ==========
#
#info "Creating Tier 3 CA..."
#sleep 120
#create_ca "tier3-ca" "tier3-ca.localho.st"
#wait_for_running fabriccas.hlf.kungfusoftware.es
#
#info "Testing Tier 3 CA..."
#curl -k https://tier3-ca.localho.st:443/cainfo
#
#info "Registering peer identity..."
#register_user "tier3-ca" "peer" "peerpw" "peer" "Tier3MSP"
#
#info "Deploying Tier3 peers..."
#create_peer "mineradora" "mineradora.localho.st" "tier3"
#wait_for_running fabricpeers.hlf.kungfusoftware.es
#
## ========== ORDERER CA + ORDERERS ==========
#
#info "Creating Orderer CA..."
#create_ca "ord-ca" "ord-ca.localho.st"
#wait_for_running fabriccas.hlf.kungfusoftware.es
#
#info "Registering orderer identity..."
#register_user "ord-ca" "orderer" "ordererpw" "orderer" "OrdererMSP"
#
#info "Deploying orderers..."
#ORDERERS=("ord-node1 orderer0-ord.localho.st admin-orderer0-ord.localho.st"
#        "ord-node2 orderer1-ord.localho.st admin-orderer1-ord.localho.st"
#        "ord-node3 orderer2-ord.localho.st admin-orderer2-ord.localho.st"
#        "ord-node4 orderer3-ord.localho.st admin-orderer3-ord.localho.st")
#
#for ord in "${ORDERERS[@]}"; do
#create_orderer $ord
#done
#
#wait_for_running fabricorderernodes.hlf.kungfusoftware.es
#
#info "Registering and enrolling OrdererMSP admin..."
#register_user "ord-ca" "admin" "adminpw" "admin" "OrdererMSP"
#create_identity "orderer-admin-sign" "ord-ca" "ca" "OrdererMSP" "admin" "adminpw"
#create_identity "orderer-admin-tls"  "ord-ca" "tlsca" "OrdererMSP" "admin" "adminpw"
#
#info "Registering and enrolling Tier1MSP admin..."
#register_user "tier1-ca" "admin" "adminpw" "admin" "Tier1MSP"
#create_identity "tier1-admin" "tier1-ca" "ca" "Tier1MSP" "admin" "adminpw"
#
#info "Registering and enrolling Tier2MSP admin..."
#register_user "tier2-ca" "admin" "adminpw" "admin" "Tier2MSP"
#create_identity "tier2-admin" "tier2-ca" "ca" "Tier2MSP" "admin" "adminpw"
#
#info "Registering and enrolling Tier3MSP admin..."
#register_user "tier3-ca" "admin" "adminpw" "admin" "Tier3MSP"
#create_identity "tier3-admin" "tier3-ca" "ca" "Tier3MSP" "admin" "adminpw"
#
#info "Cluster and network bootstrapping complete."
#kubectl get pods
#
#info "Creating Main Channel..."
#
#export IDENT_12=$(printf "%16s" "")
#
##tls CA certificate
#export ORDERER_TLS_CERT=$(kubectl get fabriccas ord-ca -o=jsonpath='{.status.tlsca_cert}' | sed -e "s/^/${IDENT_12}/" )
#
#export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
#export ORDERER1_TLS_CERT=$(kubectl get fabricorderernodes ord-node2 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
#export ORDERER2_TLS_CERT=$(kubectl get fabricorderernodes ord-node3 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
#export ORDERER3_TLS_CERT=$(kubectl get fabricorderernodes ord-node4 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
#
#export ORDERER0_SIGN_CERT=$(kubectl get fabricorderernodes ord-node1 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
#export ORDERER1_SIGN_CERT=$(kubectl get fabricorderernodes ord-node2 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
#export ORDERER2_SIGN_CERT=$(kubectl get fabricorderernodes ord-node3 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
#export ORDERER3_SIGN_CERT=$(kubectl get fabricorderernodes ord-node4 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
#
#envsubst < main-channel-config.yaml.tpl | kubectl apply -f -
#
#sleep 15
#
#info "Joining peers..."
#
#export IDENT_8=$(printf "%8s" "")
#export CHANNEL_NAME="esg-channel"
#export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_8}/")
#export ORDERER0_URL="grpcs://ord-node1.default:7050"
#export PEER_NAMESPACE="default"
#
## Define all org-specific parameters
#ORG_NAMES=("tier1" "tier2" "tier3")
#MSP_IDS=("Tier1MSP" "Tier2MSP" "Tier3MSP")
#SECRET_NAMES=("tier1-admin" "tier2-admin" "tier3-admin")
#PEER_NAMES=("montadora" "vendedor-pneu" "mineradora")
#
## Loop through each organization
#for i in "${!ORG_NAMES[@]}"; do
#export ORG_NAME="${ORG_NAMES[$i]}"
#export MSP_ID="${MSP_IDS[$i]}"
#export SECRET_NAME="${SECRET_NAMES[$i]}"
#export PEER_NAME="${PEER_NAMES[$i]}"
#export SECRET_NAMESPACE="default"
#
#info "Applying channel configuration for ${ORG_NAME} (${MSP_ID})..."
#
## Run envsubst on your template and apply the resulting YAML
#envsubst < channel-config.yaml.tpl | kubectl apply -f -
#sleep 10
#done
#
#sleep 5
#
#info "Installing Chaincode..."
#
#info "Building custom chaincode Docker image..."
#
#cd contract/
#
##Build the image with a different tag
#docker build -t mychaincode:latest .
#
#cd ..
#
##Load the image into kind cluster
#kind load docker-image mychaincode:latest --name kind
#
#info "Preparing connection string for a peer..."
#
## This identity will register and enroll the user
## remove any existing previous identity
#kubectl hlf identity delete --name tier1-admin --namespace default
#kubectl delete fabricnetworkconfigs.hlf.kungfusoftware.es tier1-cp
#
#sleep 5
#
## recreate
#kubectl hlf identity create --name tier1-admin --namespace default \
#--ca-name tier1-ca --ca-namespace default \
#--ca ca --mspid Tier1MSP --enroll-id explorer-admin --enroll-secret explorer-adminpw \
#--ca-enroll-id=enroll --ca-enroll-secret=enrollpw --ca-type=admin
#
#sleep 5
#
#kubectl hlf networkconfig create --name=tier1-cp \
#-o Tier1MSP -o OrdererMSP -c esg-channel \
#--identities=tier1-admin.default --secret=tier1-cp
#
#sleep 10
#
## This identity will register and enroll the user
## remove any existing previous identity
#kubectl hlf identity delete --name tier2-admin --namespace default
##kubectl delete fabricnetworkconfigs.hlf.kungfusoftware.es tier2-cp
#
#sleep 5
#
## recreate
#kubectl hlf identity create --name tier2-admin --namespace default \
#--ca-name tier2-ca --ca-namespace default \
#--ca ca --mspid Tier2MSP --enroll-id explorer-admin --enroll-secret explorer-adminpw \
#--ca-enroll-id=enroll --ca-enroll-secret=enrollpw --ca-type=admin
#
#sleep 5
#
#kubectl hlf networkconfig create --name=tier2-cp \
#-o Tier2MSP -o OrdererMSP -c esg-channel \
#--identities=tier2-admin.default --secret=tier2-cp
#
#sleep 10
#
## This identity will register and enroll the user
## remove any existing previous identity
#kubectl hlf identity delete --name tier3-admin --namespace default
#kubectl delete fabricnetworkconfigs.hlf.kungfusoftware.es tier3-cp
#
#sleep 5
#
## recreate
#kubectl hlf identity create --name tier3-admin --namespace default \
#--ca-name tier3-ca --ca-namespace default \
#--ca ca --mspid Tier3MSP --enroll-id explorer-admin --enroll-secret explorer-adminpw \
#--ca-enroll-id=enroll --ca-enroll-secret=enrollpw --ca-type=admin
#
#sleep 5
#
#kubectl hlf networkconfig create --name=tier3-cp \
#-o Tier3MSP -o OrdererMSP -c esg-channel \
#--identities=tier3-admin.default --secret=tier3-cp

#sleep 10

#info "Fetching the connection string from the Kubernetes secret..."
#kubectl get secret tier1-cp -o jsonpath="{.data.config\.yaml}" | base64 --decode > tier1.yaml
#kubectl get secret tier2-cp -o jsonpath="{.data.config\.yaml}" | base64 --decode > tier2.yaml
#kubectl get secret tier3-cp -o jsonpath="{.data.config\.yaml}" | base64 --decode > tier3.yaml

#sleep 5

#info "Creating metadata file..."
## remove the code.tar.gz chaincode.tgz if they exist
#rm -f code.tar.gz chaincode.tgz

export CHAINCODE_NAME=asset
export CHAINCODE_LABEL=asset

#cat << METADATA-EOF > "metadata.json"
#{
#"type": "ccaas",
#"label": "${CHAINCODE_LABEL}"
#}
#METADATA-EOF
#sleep 5

#info "Preparing connection file..."
## chaincode as a service
#cat > "connection.json" <<CONN_EOF
#{
#"address": "${CHAINCODE_NAME}:7052",
#"dial_timeout": "10s",
#"tls_required": false
#}
#CONN_EOF
#sleep 5

#tar cfz code.tar.gz connection.json
#tar cfz chaincode.tgz metadata.json code.tar.gz

export PACKAGE_ID=$(kubectl hlf chaincode calculatepackageid --path=chaincode.tgz --language=node --label=$CHAINCODE_LABEL)

#info "PACKAGE_ID=$PACKAGE_ID"
#
#kubectl hlf chaincode install --path=./chaincode.tgz \
#--config=tier1.yaml --language=golang --label=$CHAINCODE_LABEL --user=tier1-admin-default --peer=montadora.default
#
#kubectl hlf chaincode install --path=./chaincode.tgz \
#--config=tier2.yaml --language=golang --label=$CHAINCODE_LABEL --user=tier2-admin-default --peer=vendedor-pneu.default
#
#kubectl hlf chaincode install --path=./chaincode.tgz \
#--config=tier3.yaml --language=golang --label=$CHAINCODE_LABEL --user=tier3-admin-default --peer=mineradora.default
#
#sleep 5
#
#info "Checking chaincode installation..."
#kubectl hlf chaincode queryinstalled --config=tier1.yaml --user=tier1-admin-default --peer=montadora.default
#kubectl hlf chaincode queryinstalled --config=tier2.yaml --user=tier2-admin-default --peer=vendedor-pneu.default
#kubectl hlf chaincode queryinstalled --config=tier3.yaml --user=tier3-admin-default --peer=mineradora.default
#sleep 3
#
## Create a ConfigMap with the package ID
#kubectl create configmap chaincode-config \
#--from-literal=CORE_CHAINCODE_ID_NAME="${PACKAGE_ID}" \
#--from-literal=CORE_PEER_TLS_ENABLED="false"
#
#Then deploy with the operator including environment variables
kubectl hlf externalchaincode sync --image=mychaincode:latest \
    --name=$CHAINCODE_NAME \
    --namespace=default \
    --package-id=$PACKAGE_ID \
    --tls-required=false \
    --replicas=1 \
    --env="CORE_CHAINCODE_ID_NAME=${PACKAGE_ID}"

sleep 10

info "Approving chaincode..."

export SEQUENCE=1
export VERSION="1.0"
export ENDORSEMENT_POLICY="OR('Tier1MSP.member', 'Tier2MSP.member', 'Tier3MSP.member')"
info "SEQUENCE VALUE: ${SEQUENCE}"
info "VERSION VALUE: ${VERSION}"
info "ENDORSEMENT POLICY: ${ENDORSEMENT_POLICY}"

sleep 5

kubectl hlf chaincode approveformyorg --config=tier1.yaml --user=tier1-admin-default --peer=montadora.default \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=esg-channel

kubectl hlf chaincode approveformyorg --config=tier2.yaml --user=tier2-admin-default --peer=vendedor-pneu.default \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=esg-channel

kubectl hlf chaincode approveformyorg --config=tier3.yaml --user=tier3-admin-default --peer=mineradora.default \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=esg-channel

sleep 15

info "Commiting chaincode..."
kubectl hlf chaincode commit --config=tier1.yaml --user=tier1-admin-default --mspid=Tier1MSP \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=esg-channel

