#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-quarkus-mesh}
# Push via localhost; cluster will pull via registry.localhost
REGISTRY_HOST=${REGISTRY_HOST:-localhost}
REGISTRY_PORT=${REGISTRY_PORT:-5001}
REG=${REGISTRY_HOST}:${REGISTRY_PORT}

# Clean and build container images using Jib via Quarkus for each service
echo "Cleaning and building inventory-service..."
./inventory-service/gradlew -p inventory-service -q \
  -Dquarkus.container-image.build=true \
  -Dquarkus.container-image.push=true \
  -Dquarkus.container-image.registry=${REG} \
  -Dquarkus.container-image.insecure=true \
  clean build -x test

echo "Cleaning and building order-service..."
./order-service/gradlew -p order-service -q \
  -Dquarkus.container-image.build=true \
  -Dquarkus.container-image.push=true \
  -Dquarkus.container-image.registry=${REG} \
  -Dquarkus.container-image.insecure=true \
  clean build -x test

echo "Cleaning and building payment-service..."
./payment-service/gradlew -p payment-service -q \
  -Dquarkus.container-image.build=true \
  -Dquarkus.container-image.push=true \
  -Dquarkus.container-image.registry=${REG} \
  -Dquarkus.container-image.insecure=true \
  clean build -x test

# Deploy apps using Helm
helm upgrade --install inventory-service helm/inventory-service --namespace apps --create-namespace
helm upgrade --install order-service helm/order-service --namespace apps
helm upgrade --install payment-service helm/payment-service --namespace apps

echo "Wait for rollouts..."
kubectl -n apps rollout status deploy/inventory-service
kubectl -n apps rollout status deploy/order-service
kubectl -n apps rollout status deploy/payment-service

echo "Apps deployed. Services in namespace apps:"
kubectl get svc -n apps
