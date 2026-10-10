#!/usr/bin/env bash
set -Eeuo pipefail

CLUSTER_NAME="demo"
KUBE_CONTEXT="kind-${CLUSTER_NAME}"
IMAGE_REPOSITORY="eb-assessment-service"
IMAGE_TAG="review"
INGRESS_CHART_VERSION="4.10.1"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

for tool in docker kind kubectl helm; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$tool" >&2
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker is not running or the current user cannot access it." >&2
  exit 1
fi

if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  echo "Reusing kind cluster '$CLUSTER_NAME'."
else
  echo "Creating kind cluster '$CLUSTER_NAME'."
  KIND_CONFIG="$(mktemp)"
  trap 'rm -f "$KIND_CONFIG"' EXIT
  cat >"$KIND_CONFIG" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
EOF
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG" --wait 5m
  trap - EXIT
  rm -f "$KIND_CONFIG"
fi

echo "Installing or upgrading ingress-nginx."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version "$INGRESS_CHART_VERSION" \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.ingressClass=nginx \
  --set controller.hostPort.enabled=true \
  --set controller.hostPort.ports.http=80 \
  --set controller.hostPort.ports.https=443 \
  --set controller.service.type=ClusterIP \
  --kube-context "$KUBE_CONTEXT" \
  --wait \
  --timeout 5m

echo "Building ${IMAGE_REPOSITORY}:${IMAGE_TAG}."
docker build \
  --file "$ROOT_DIR/service/Dockerfile" \
  --tag "${IMAGE_REPOSITORY}:${IMAGE_TAG}" \
  "$ROOT_DIR/service"

echo "Loading the image into kind cluster '$CLUSTER_NAME'."
kind load docker-image "${IMAGE_REPOSITORY}:${IMAGE_TAG}" --name "$CLUSTER_NAME"

echo "Installing or upgrading Helm release 'demo' in namespace 'demo'."
helm upgrade --install demo "$ROOT_DIR/chart" \
  --namespace demo \
  --create-namespace \
  --kube-context "$KUBE_CONTEXT" \
  --set image.repository="$IMAGE_REPOSITORY" \
  --set image.tag="$IMAGE_TAG" \
  --wait \
  --timeout 5m

echo "Setup complete. Check the deployment with: kubectl --context ${KUBE_CONTEXT} -n demo get pods,svc,ingress"
