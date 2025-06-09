# MOVchain
Tutorial de como subir a rede para Proof of Concept ESG.

*Baseado em: [Workshop to create your first HLF network](https://github.com/kfsoftware/meetup-hlf-3-0?tab=readme-ov-file#14-completion).*

## Extra: Remoção de Dependências
Caso queira instalar as dependências do zero, use essa parte do tutorial para remover as versões de Docker, Kubernetes, Go e Kind que já estão instaladas no seu sistema.

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

### Remoção do Kubernetes
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

### Remoção do Kind
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

### Instalação Kubernetes
Para instalação do Kubernetes faremos:
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

### Instalação Kind (usando o Go)
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
Usamos como base a Fabric Network de um [repositório](https://github.com/kapfw/fabric-test-01) do GitHub criado pelo Kapfw.

### Instalação

O primeiro passo será clonar o repositório:
```bash
git clone https://github.com/joaozacheo/pocESG.git
```

Depois devemos executar o script de instalação:
```bash
# Entrar no diretório clonado
cd pocESG

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
O próximo passo é executar o script ``run.sh`` personalizado para ESG.

```bash
# Entrar no diretório
cd pocESG

# Tornar o script de deploy executável
chmod +x runESG.sh

# Executar o script
./runESG.sh
```

> ⚠️ **Atenção:** É possível que alguns erros interrompam a execução do deploy. Caso isso ocorra, abra o arquivo ``runESG.sh`` no editor de texto de sua preferência e comente as linhas, desde o início do script (Indicado por "SCRIPT START") até a última parte executada sem erros. Depois volte ao terminal e execute o arquivo novamente.

## Interagindo com a Blockchain
Se todo o deploy ocorrer sem erros, estamos prontos para começar a interagir com a blockchain. Vamos usar o plugin HLF-Operator do Kubernetes para interagir com o chaincode. O plugin providencia uma interface mais user-friendly. Para facilitar ainda mais as leituras de assets, vamos usar o ``jq`` para manipular JSON's.

#### Instalação do jq
```bash
sudo apt update
sudo apt upgrade

sudo apt install jq
```

### Exemplo de Supply Chain
Para demonstrar como interagir com a blockchain iremos utilizar um caso exemplo.

#### Criação de Assets (Escrita)
```bash
# == Matéria-Prima ==============================================

# Cria Ferro - Mineradora
kubectl hlf chaincode invoke --config=tier3.yaml \
    --user=tier3-admin-default --peer=mineradora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "ferro1" -a "Ferro Bruto" -a "B" -a "Mineradora"

# Cria Borracha - Borracharia
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "borracha1" -a "Borracha Natural" -a "A" -a "Borracharia"

# Cria Plástico - Fábrica de Polímeros
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "plastico1" -a "Polímero ABS" -a "C" -a "Fabrica_Polimeros"
```
```bash
# == Produtos Intermediários =====================================

# Cria Motor
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "motor1" -a "Motor Elétrico" -a "A" -a "Vendedor_Motor"

# Cria Roda
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "roda1" -a "Roda de Liga" -a "A" -a "Vendedor_Roda"

# Cria Volante
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "volante1" -a "Volante Ergonômico" -a "B" -a "Vendedor_Volante"
```
```bash
# == Produto Final =====================================

# Cria Carro
kubectl hlf chaincode invoke --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateAsset -a "carro1" -a "Carro Elétrico Modelo X" -a "A" -a "Montadora"
```

#### Criação de Transações (Escrita)

```bash
# == Matéria-Prima para Intermediários =====================================

# Transfere Ferro da Mineradora para Vendedor Motor
kubectl hlf chaincode invoke --config=tier3.yaml \
    --user=tier3-admin-default --peer=mineradora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=TransferAsset -a "ferro1" -a "Vendedor_Motor" -a "tx001"

# Transfere Borracha da Borracharia para Vendedor Roda
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=TransferAsset -a "borracha1" -a "Vendedor_Roda" -a "tx002"

# Transfere Plástico da Fábrica Polímeros para Vendedor Volante
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=TransferAsset -a "plastico1" -a "Vendedor_Volante" -a "tx003"
```
```bash
# == Intermediários para Produto Final =====================================

# Transfere Motor para Montadora
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=TransferAsset -a "motor1" -a "Montadora" -a "tx004"

# Transfere Roda para Montadora
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=TransferAsset -a "roda1" -a "Montadora" -a "tx005"

# Transfere Volante para Montadora
kubectl hlf chaincode invoke --config=tier2.yaml \
    --user=tier2-admin-default --peer=vendedor-pneu.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=TransferAsset -a "volante1" -a "Montadora" -a "tx006"
```
```bash
# == Registro do Produto Final =====================================

# Registra o uso dos componentes no produto final
kubectl hlf chaincode invoke --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateTransaction -a "tx007" -a "Montadora" -a "Carro_Assembly" -a "motor1"

kubectl hlf chaincode invoke --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateTransaction -a "tx008" -a "Montadora" -a "Carro_Assembly" -a "roda1"

kubectl hlf chaincode invoke --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=CreateTransaction -a "tx009" -a "Montadora" -a "Carro_Assembly" -a "volante1"
```

#### Commandos Query (Leitura)
```bash
# Lê todos os assets
kubectl hlf chaincode query --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=GetAllAssets | jq

# Lê asset específico
kubectl hlf chaincode query --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=GetAsset -a "carro1" | jq

# Lê todas as transações
kubectl hlf chaincode query --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=GetAllTransactions | jq

# Lê transação específica
kubectl hlf chaincode query --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=GetTransaction -a "tx001" | jq

# Lê histórico de transações de um asset (supply chain traceability)
kubectl hlf chaincode query --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=GetAssetHistory -a "motor1" | jq
```

#### Atualizando Asset
```bash
# Atualiza dono (owner) do asset
kubectl hlf chaincode invoke --config=tier1.yaml \
    --user=tier1-admin-default --peer=montadora.default \
    --chaincode=asset --channel=esg-channel \
    --fcn=UpdateAsset -a "carro1" -a "A" -a "CarroPlus"
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

<br>

## Autor
| [<img src="https://avatars.githubusercontent.com/u/95360206?v=4" width=120 height=120 style="border-radius:50%"><br><sub>João Zachêo</sub>](https://github.com/joaozacheo) |  
| :---: |

