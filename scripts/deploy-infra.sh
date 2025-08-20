#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy infrastructure using Helm
# Grafana
helm upgrade --install grafana grafana/grafana -f helm/infra-charts/grafana-values.yaml --namespace observability --create-namespace

# Loki 3.5.3 (SingleBinary) via manifests + Promtail via Helm
kubectl create namespace logging >/dev/null 2>&1 || true
helm uninstall loki -n logging >/dev/null 2>&1 || true
helm upgrade --install promtail grafana/promtail -f helm/infra-charts/promtail-values.yaml \
  --namespace logging --create-namespace --wait
kubectl apply -f helm/infra-charts/loki-manifests.yaml
kubectl -n logging rollout status statefulset/loki
helm upgrade --install jaeger jaegertracing/jaeger -f helm/infra-charts/jaeger-values.yaml --namespace observability
helm upgrade --install kafka bitnami/kafka -f helm/infra-charts/kafka-values.yaml --namespace data --create-namespace

# Apply Istio ingress routes for Grafana and Jaeger
kubectl apply -f helm/infra-charts/istio-ingress.yaml