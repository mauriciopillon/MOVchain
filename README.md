# POC ESG
Tutorial de como subir a rede para Proof of Concept ESG.

Tutorial baseado em [Workshop to create your first HLF network](https://github.com/kfsoftware/meetup-hlf-3-0?tab=readme-ov-file#14-completion).

## Extra: Remoção de Dependências
Caso queira instalar as dependências do zero, use essa parte do tutorial para remover as versões de Docker, Kubectl, Go e KinD que já estão instaladas no seu sistema.

### Eliminar Exports (.bashrc & .profile)
Entre nos arquivos ``.bashrc`` e ``.profile`` e procure pelos ``exports`` inseridos manualmente. Exemplos:
```bash
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/PATH/go/bin
export PATH="$PATH:/home/PATH/istio-1.20.0/bin"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

Em seguida, recarregue o shell:
```bash
source ~/.bashrc
source ~/.profile
```

### Remoção do Docker
Execute os comandos abaixo no terminal:
```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.asc

sudo apt autoremove -y
```

### Remoção do Kubectl
Execute os comandos abaixo no terminal:
```bash
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*

sudo rm -rf ~/.kube

sudo apt autoremove -y
```

### Remoção do Go
Execute os comandos abaixo no terminal:
```bash
sudo rm -rf /usr/local/go
sudo rm -rf ~/go
```

### Remoção do KinD
Execute os comandos abaixo no terminal:
```bash
# Caso instalado com Go:
rm -f ~/go/bin/kind

# Caso instalado pelos binaries:
sudo rm -f /usr/local/bin/kind
```

Pronto! Agora você pode seguir com o tutorial de instalação de dependências sem problemas.

## Instalação de Dependências

```bash
sudo apt update
sudo apt upgrade
```

### Instalação Docker
Para instalação do Docker faremos:
```bash
# Repositório apt
sudo apt-get update
sudo apt-get install ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Instalação dos pacotes
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Teste da imagem
sudo docker run hello-world

# Caso erro: "cannot connect to the docker daemon.."
sudo systemctl restart docker

# Criar grupo docker com usuário (dispensar uso de sudo para docker)
sudo groupadd docker

sudo usermod -aG docker $USER

# É necessário rebootar se estiver numa VM
sudo reboot

# Após o reboot, teste se o comando funciona sem sudo
docker ps
```

### Instalação Kubectl
Para instalação do Kubectl faremos:
```bash
# Download da última versão estável dispoível
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Instalação do pacote
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Teste versão
kubectl version 
```

### Instalação Go
Para instalação do Go faremos:
```bash
# Donwload da versão especificada (mais recente no momento)
wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz

# Descompactar pacote
sudo tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz

# Adicionar variável de ambiente em PATH (~/.bashrc)
export PATH=$PATH:/usr/local/go/bin

# Recarregue o shell
source ~/.bashrc

# Teste versão
go version
```

### Instalação KinD (usando o Go)
Para instalação do KinD faremos:
```bash
# Instale kind
go install sigs.k8s.io/kind@v0.29.0

# Teste versão
kind version

# Caso erro: "kind: command not found", adicione kind em PATH (~/.bashrc)
export PATH=$PATH:/home/<SEU_USUÁRIO>/go/bin
```

### Teste Geral de Ambiente
Para testar se tudo está funcionando, execute os comandos abaixo no terminal:
```bash
kind create cluster

kubectl cluster-info

docker ps

kubectl get nodes

kind delete cluster
```

## Configuração de Rede
Usaremos como base a Fabric Network de um [repositório](https://github.com/kapfw/fabric-test-01) do GitHub criado pelo Kapfw.

### Instalação

O primeiro passo será clonar o repositório:
```bash
git clone https://github.com/kapfw/fabric-test-01.git
```

Depois devemos executar o script de instalação:
```bash
# Entrar no diretório clonado
cd fabric-test-01

# Tornar o script de instalação executável
chmod +x install.sh

# Executar o script
./install.sh
```

Adicione os ``exports`` ao ``.bashrc``:

```bash
export PATH="$PATH:$PWD/istio-1.20.0/bin"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

### Deploy
O próximo passo é criar o script ``run.sh`` personalizado para ESG.

Para isso devemos criar o arquivo ``runESG.sh`` e colar o código abaixo:
```bash
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

info "Creating cluster..."
kind delete cluster --name kind || true
kind create cluster --config=./kind-config.yaml

info "Installing Istio in k8s cluster..."
kubectl create namespace istio-system || true
istioctl operator init
kubectl apply -f ./istio-config.yaml
kubectl apply -f ./istio-configmap.yaml

info "Installing HLF operator..."
helm repo add kfs https://kfsoftware.github.io/hlf-helm-charts --force-update
helm upgrade --install hlf-operator --version=$HLF_OPERATOR_VERSION -- kfs/hlf-operator

# ========== ORG1 CA + PEERS ==========

info "Creating Org1 CA..."
sleep 120
create_ca "org1-ca" "org1-ca.localho.st"
wait_for_running fabriccas.hlf.kungfusoftware.es

info "Testing Org1 CA..."
curl -k https://org1-ca.localho.st:443/cainfo

info "Registering peer identity..."
register_user "org1-ca" "peer" "peerpw" "peer" "Org1MSP"

info "Deploying Org1 peers..."
create_peer "org1-peer0" "peer0-org1.localho.st" "org1"
create_peer "org1-peer1" "peer1-org1.localho.st" "org1"
wait_for_running fabricpeers.hlf.kungfusoftware.es

# ========== ORG2 CA + PEERS ==========

info "Creating Org2 CA..."
create_ca "org2-ca" "org2-ca.localho.st"
wait_for_running fabriccas.hlf.kungfusoftware.es

info "Testing Org2 CA..."
curl -k https://org2-ca.localho.st:443/cainfo

info "Registering peer identity..."
register_user "org2-ca" "peer" "peerpw" "peer" "Org2MSP"

info "Deploying Org2 peers..."
create_peer "org2-peer0" "peer0-org2.localho.st" "org2"
create_peer "org2-peer1" "peer1-org2.localho.st" "org2"
wait_for_running fabricpeers.hlf.kungfusoftware.es
# ========== ORDERER CA + ORDERERS ==========

info "Creating Orderer CA..."
create_ca "ord-ca" "ord-ca.localho.st"
wait_for_running fabriccas.hlf.kungfusoftware.es

info "Registering orderer identity..."
register_user "ord-ca" "orderer" "ordererpw" "orderer" "OrdererMSP"

info "Deploying orderers..."
ORDERERS=("ord-node1 orderer0-ord.localho.st admin-orderer0-ord.localho.st"
          "ord-node2 orderer1-ord.localho.st admin-orderer1-ord.localho.st"
          "ord-node3 orderer2-ord.localho.st admin-orderer2-ord.localho.st"
          "ord-node4 orderer3-ord.localho.st admin-orderer3-ord.localho.st")

for ord in "${ORDERERS[@]}"; do
  create_orderer $ord
done

wait_for_running fabricorderernodes.hlf.kungfusoftware.es

info "Registering and enrolling OrdererMSP admin..."
register_user "ord-ca" "admin" "adminpw" "admin" "OrdererMSP"
create_identity "orderer-admin-sign" "ord-ca" "ca" "OrdererMSP" "admin" "adminpw"
create_identity "orderer-admin-tls"  "ord-ca" "tlsca" "OrdererMSP" "admin" "adminpw"

info "Registering and enrolling Org1MSP admin..."
register_user "org1-ca" "admin" "adminpw" "admin" "Org1MSP"
create_identity "org1-admin" "org1-ca" "ca" "Org1MSP" "admin" "adminpw"

info "Registering and enrolling Org2MSP admin..."
register_user "org2-ca" "admin" "adminpw" "admin" "Org2MSP"
create_identity "org2-admin" "org2-ca" "ca" "Org2MSP" "admin" "adminpw"

info "Cluster and network bootstrapping complete."
kubectl get pods

info "Creating Main Channel..."

export IDENT_12=$(printf "%16s" "")

 tls CA certificate
export ORDERER_TLS_CERT=$(kubectl get fabriccas ord-ca -o=jsonpath='{.status.tlsca_cert}' | sed -e "s/^/${IDENT_12}/" )

export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER1_TLS_CERT=$(kubectl get fabricorderernodes ord-node2 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER2_TLS_CERT=$(kubectl get fabricorderernodes ord-node3 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER3_TLS_CERT=$(kubectl get fabricorderernodes ord-node4 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_12}/" )

export ORDERER0_SIGN_CERT=$(kubectl get fabricorderernodes ord-node1 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER1_SIGN_CERT=$(kubectl get fabricorderernodes ord-node2 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER2_SIGN_CERT=$(kubectl get fabricorderernodes ord-node3 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )
export ORDERER3_SIGN_CERT=$(kubectl get fabricorderernodes ord-node4 -o=jsonpath='{.status.signCert}' | sed -e "s/^/${IDENT_12}/" )

envsubst < main-channel-config.yaml.tpl | kubectl apply -f -

sleep 5

info "Joining peers..."

export IDENT_8=$(printf "%8s" "")
export CHANNEL_NAME="demo"
export ORDERER0_TLS_CERT=$(kubectl get fabricorderernodes ord-node1 -o=jsonpath='{.status.tlsCert}' | sed -e "s/^/${IDENT_8}/")
export ORDERER0_URL="grpcs://ord-node1.default:7050"
export PEER_NAMESPACE="default"

# Define all org-specific parameters
ORG_NAMES=("org1" "org2")
MSP_IDS=("Org1MSP" "Org2MSP")
SECRET_NAMES=("org1-admin" "org2-admin")

# Loop through each organization
for i in "${!ORG_NAMES[@]}"; do
  export ORG_NAME="${ORG_NAMES[$i]}"
  export MSP_ID="${MSP_IDS[$i]}"
  export SECRET_NAME="${SECRET_NAMES[$i]}"
  export SECRET_NAMESPACE="default"

  info "Applying channel configuration for ${ORG_NAME} (${MSP_ID})..."

  # Run envsubst on your template and apply the resulting YAML
  envsubst < channel-config.yaml.tpl | kubectl apply -f -
done

sleep 5

info "Installing Chaincode..."
info "Preparing connection string for a peer..."

# This identity will register and enroll the user
# remove any existing previous identity
kubectl hlf identity delete --name org1-admin --namespace default
# recreate
kubectl hlf identity create --name org1-admin --namespace default \
    --ca-name org1-ca --ca-namespace default \
    --ca ca --mspid Org1MSP --enroll-id explorer-admin --enroll-secret explorer-adminpw \
    --ca-enroll-id=enroll --ca-enroll-secret=enrollpw --ca-type=admin

sleep 5

kubectl hlf networkconfig create --name=org1-cp \
  -o Org1MSP -o OrdererMSP -c demo \
  --identities=org1-admin.default --secret=org1-cp

sleep 10

# This identity will register and enroll the user
# remove any existing previous identity
kubectl hlf identity delete --name org2-admin --namespace default
# recreate
kubectl hlf identity create --name org2-admin --namespace default \
    --ca-name org2-ca --ca-namespace default \
    --ca ca --mspid Org2MSP --enroll-id explorer-admin --enroll-secret explorer-adminpw \
    --ca-enroll-id=enroll --ca-enroll-secret=enrollpw --ca-type=admin

sleep 5

kubectl hlf networkconfig create --name=org2-cp \
  -o Org2MSP -o OrdererMSP -c demo \
  --identities=org2-admin.default --secret=org2-cp

sleep 10

info "Fetching the connection string from the Kubernetes secret..."
kubectl get secret org1-cp -o jsonpath="{.data.config\.yaml}" | base64 --decode > org1.yaml
kubectl get secret org2-cp -o jsonpath="{.data.config\.yaml}" | base64 --decode > org2.yaml

sleep 5

info "Creating metadata file..."
# remove the code.tar.gz chaincode.tgz if they exist
rm -f code.tar.gz chaincode.tgz

export CHAINCODE_NAME=asset
export CHAINCODE_LABEL=asset

cat << METADATA-EOF > "metadata.json"
{
    "type": "ccaas",
    "label": "${CHAINCODE_LABEL}"
}
METADATA-EOF
sleep 5

info "Preparing connection file..."
## chaincode as a service
cat > "connection.json" <<CONN_EOF
{
  "address": "${CHAINCODE_NAME}:7052",
  "dial_timeout": "10s",
  "tls_required": false
}
CONN_EOF
sleep 5

tar cfz code.tar.gz connection.json
tar cfz chaincode.tgz metadata.json code.tar.gz

export PACKAGE_ID=$(kubectl hlf chaincode calculatepackageid --path=chaincode.tgz --language=golang --label=$CHAINCODE_LABEL)

info "PACKAGE_ID=$PACKAGE_ID"

info "Installing chaincode on peers..."
kubectl hlf chaincode install --path=./chaincode.tgz \
    --config=org1.yaml --language=golang --label=$CHAINCODE_LABEL --user=org1-admin-default --peer=org1-peer0.default

kubectl hlf chaincode install --path=./chaincode.tgz \
    --config=org1.yaml --language=golang --label=$CHAINCODE_LABEL --user=org1-admin-default --peer=org1-peer1.default

kubectl hlf chaincode install --path=./chaincode.tgz \
    --config=org2.yaml --language=golang --label=$CHAINCODE_LABEL --user=org2-admin-default --peer=org2-peer0.default

kubectl hlf chaincode install --path=./chaincode.tgz \
    --config=org2.yaml --language=golang --label=$CHAINCODE_LABEL --user=org2-admin-default --peer=org2-peer1.default
sleep 5

info "Deploying chaincode as external service..."
# Create chaincode deployment
cat << DEPLOYMENT-EOF > chaincode-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${CHAINCODE_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${CHAINCODE_NAME}
  template:
    metadata:
      labels:
        app: ${CHAINCODE_NAME}
    spec:
      containers:
      - name: chaincode
        image: golang:1.19-alpine
        command: ["/bin/sh"]
        args: ["-c", "cd /chaincode && go mod tidy && go run chaincode.go"]
        ports:
        - containerPort: 7052
        env:
        - name: CHAINCODE_ADDRESS
          value: "0.0.0.0:7052"
        - name: CHAINCODE_ID
          value: "${PACKAGE_ID}"
        volumeMounts:
        - name: chaincode-source
          mountPath: /chaincode
      volumes:
      - name: chaincode-source
        configMap:
          name: ${CHAINCODE_NAME}-source
---
apiVersion: v1
kind: Service
metadata:
  name: ${CHAINCODE_NAME}
spec:
  selector:
    app: ${CHAINCODE_NAME}
  ports:
  - protocol: TCP
    port: 7052
    targetPort: 7052
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CHAINCODE_NAME}-source
data:
  chaincode.go: |
$(cat ./contract/contract.go | sed 's/^/    /')
  go.mod: |
$(cat ./contract/go.mod | sed 's/^/    /')
DEPLOYMENT-EOF

kubectl apply -f chaincode-deployment.yaml

info "Waiting for chaincode service to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/${CHAINCODE_NAME}
sleep 10

info "Checking chaincode installation..."
kubectl hlf chaincode queryinstalled --config=org1.yaml --user=org1-admin-default --peer=org1-peer0.default
kubectl hlf chaincode queryinstalled --config=org2.yaml --user=org2-admin-default --peer=org2-peer0.default
sleep 3

info "Approving chaincode..."

export SEQUENCE=1
export VERSION="1.0"
export ENDORSEMENT_POLICY="OR('Org1MSP.member', 'Org2MSP.member')"
info "SEQUENCE VALUE: ${SEQUENCE}"
info "VERSION VALUE: ${VERSION}"
info "ENDORSEMENT POLICY: ${ENDORSEMENT_POLICY}"

sleep 5

kubectl hlf chaincode approveformyorg --config=org1.yaml --user=org1-admin-default --peer=org1-peer0.default \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=demo

kubectl hlf chaincode approveformyorg --config=org2.yaml --user=org2-admin-default --peer=org2-peer0.default \
    --package-id=$PACKAGE_ID \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=demo
sleep 5

info "Commiting chaincode..."
kubectl hlf chaincode commit --config=org1.yaml --user=org1-admin-default --mspid=Org1MSP \
    --version "$VERSION" --sequence "$SEQUENCE" --name=asset \
    --policy="${ENDORSEMENT_POLICY}" --channel=demo
```

Depois de salvar o script dentro do diretório ``fabric-test-01``, devemos executá-lo:
```bash
# Entrar no diretório
cd fabric-test-01

# Tornar o script de deploy executável
chmod +x runESG.sh

# Executar o script
./runESG.sh
```

## Interagindo com a Blockchain
Se todo o deploy ocorrer sem erros, estamos prontos para começar a interagir com a blockchain. Vamos usar o plugin do Kubectl para interagir com o chaincode. O plugin providencia uma interface mais user-friendly. Para facilitar ainda mais as leituras de assets, vamos usar o ``jq`` para manipular JSON's.

### Instalação do jq
```bash
sudo apt update
sudo apt upgrade

sudo apt install jq
```

### Invocando uma trasação no canal
```bash
kubectl hlf chaincode invoke --config=org1.yaml \
    --user=org1-admin-default --peer=org1-peer0.default \
    --chaincode=asset --channel=demo \
    --fcn=initLedger
```

### Lendo assets no canal
```bash
kubectl hlf chaincode query --config=org1.yaml \
    --user=org1-admin-default --peer=org1-peer0.default \
    --chaincode=asset --channel=demo \
    --fcn=GetAllAssets -a '[]' | jq
```

### Criando um asset
```bash
kubectl hlf chaincode invoke --config=org1.yaml \
    --user=org1-admin-default --peer=org1-peer0.default \
    --chaincode=asset --channel=demo \
    --fcn=CreateAsset -a "asset7" -a blue -a "5" -a "tom" -a "100"
```

### Lendo o asset criado
```bash
kubectl hlf chaincode query --config=org1.yaml \
    --user=org1-admin-default --peer=org1-peer0.default \
    --chaincode=asset --channel=demo \
    --fcn=ReadAsset -a asset7 | jq
```

## Limpando o ambiente
Podemos executar os comandos abaixo no terminal para derrubar a rede criada:
```bash
kubectl delete fabricorderernodes.hlf.kungfusoftware.es --all-namespaces --all
kubectl delete fabricpeers.hlf.kungfusoftware.es --all-namespaces --all
kubectl delete fabriccas.hlf.kungfusoftware.es --all-namespaces --all
kubectl delete fabricchaincode.hlf.kungfusoftware.es --all-namespaces --all
kubectl delete fabricmainchannels --all-namespaces --all
kubectl delete fabricfollowerchannels --all-namespaces --all

# Parar o Docker
sudo systemctl stop docker
```
