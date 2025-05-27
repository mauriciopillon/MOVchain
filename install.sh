echo "Installing Istio..."
# add TARGET_ARCH=x86_64 if you are using arm64
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
# add PATH to source if you want to call it later
export PATH="$PATH:$PWD/istio-1.20.0/bin"
echo "add ISTIO PATH to source if you want to call it later"

echo "Installing helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

echo "Installing krew..."
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
echo "add KREW PATH to source if you want to call it later"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

echo "Installing kubectl plugin..."
kubectl krew install hlf

echo "Installing envsubst..."
sudo apt install gettext
