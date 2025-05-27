# Fabric-test-01

## Dependências

- **docker** (28.1.1)
- **node** (22.15.1)
- **kubectl** (1.33.0)
- **go** (1.24.3)
- **kind** (0.29.0)

## Instalação e deploy

### 1. Torne os scripts `install.sh` e `run.sh` executáveis

```
chmod +x install.sh
chmod +x run.sh
```

### 1. Execute o script de instalação

```
./install.sh
```

### 2. Adicione os exports para source

Em seu arquivo `~/.bashrc` adicione as variáveis de ambiente:

```
export PATH="$PATH:<CAMINHO/ATÉ/REPO/CLONADA>/istio-1.20.0/bin"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

Então recarregue o shell:
```
source ~/.bashrc
```

### 3. Execute o script de deploy

```
./run.sh
```

Após do fim da execução, será possivel interagir com a rede usando os comandos inclusos no chaincode.
