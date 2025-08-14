#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f k8s/namespaces.yaml

# Install Istio (using istioctl if available)
if ! command -v istioctl >/dev/null; then
  echo "istioctl not found; please install Istio CLI from https://istio.io" >&2
  exit 1
fi
istioctl install -y --set profile=demo
kubectl apply -f k8s/istio/peer-auth-strict.yaml
kubectl apply -f k8s/istio/destination-rules.yaml
kubectl apply -f k8s/istio/kafka-mtls-policy.yaml

# Deploy Kafka (ZK + Kafka) for demo
kubectl apply -f k8s/kafka/bitnami-kafka.yaml

# Deploy Jaeger all-in-one (OTLP enabled)
kubectl apply -f k8s/jaeger/jaeger.yaml

# Deploy Loki + Promtail and provision Grafana datasources
kubectl apply -f k8s/loki/loki-stack.yaml
kubectl apply -f k8s/grafana/grafana.yaml

echo "Infra deployed. Wait for pods to be Ready: kubectl get pods -A"
