#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy infrastructure using Helm
# Grafana
helm upgrade --install grafana grafana/grafana -f helm/infra-charts/grafana-values.yaml --namespace observability --create-namespace

# Replace deprecated loki-stack with official charts
helm uninstall loki -n logging >/dev/null 2>&1 || true
helm upgrade --install loki grafana/loki -f helm/infra-charts/loki-values.yaml --namespace logging --create-namespace
helm upgrade --install promtail grafana/promtail -f helm/infra-charts/promtail-values.yaml --namespace logging --create-namespace
helm upgrade --install jaeger jaegertracing/jaeger -f helm/infra-charts/jaeger-values.yaml --namespace observability
helm upgrade --install kafka bitnami/kafka -f helm/infra-charts/kafka-values.yaml --namespace data --create-namespace

# Apply Istio ingress routes for Grafana and Jaeger
kubectl apply -f helm/infra-charts/istio-ingress.yaml