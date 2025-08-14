#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-quarkus-mesh}
REGISTRY_NAME=${REGISTRY_NAME:-registry.localhost}
REGISTRY_PORT=${REGISTRY_PORT:-5001}

if ! command -v k3d >/dev/null; then
  echo "k3d is required. Install from https://k3d.io" >&2
  exit 1
fi

if ! k3d registry list | grep -q "${REGISTRY_NAME}"; then
  # Bind registry to host 0.0.0.0:PORT (accessible as localhost:PORT on host)
  k3d registry create ${REGISTRY_NAME} --port 0.0.0.0:${REGISTRY_PORT}
fi

if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Cluster ${CLUSTER_NAME} already exists"
  exit 0
fi

cat <<EOF | k3d cluster create ${CLUSTER_NAME} \
  --registry-use ${REGISTRY_NAME}:${REGISTRY_PORT} \
  --agents 2 \
  --servers 1 \
  --k3s-arg "--disable=traefik@server:0" \
  --wait
apiVersion: k3d.io/v1alpha3
kind: Simple
servers: 1
agents: 2
registries:
  use:
    - ${REGISTRY_NAME}:${REGISTRY_PORT}
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:0
EOF

echo "Cluster created: ${CLUSTER_NAME}"
