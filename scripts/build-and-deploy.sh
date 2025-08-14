#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-quarkus-mesh}
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

# Apply app manifests
kubectl apply -f k8s/apps/inventory-service.yaml
kubectl apply -f k8s/apps/order-service.yaml
kubectl apply -f k8s/apps/payment-service.yaml

echo "Wait for rollouts..."
kubectl -n apps rollout status deploy/inventory-service
kubectl -n apps rollout status deploy/order-service
kubectl -n apps rollout status deploy/payment-service

echo "Apps deployed. Services in namespace apps:"
kubectl get svc -n apps
