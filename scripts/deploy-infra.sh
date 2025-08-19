#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy infrastructure using Helm
helm upgrade --install grafana grafana/grafana -f helm/infra-charts/grafana-values.yaml --namespace observability --create-namespace
helm upgrade --install loki grafana/loki-stack -f helm/infra-charts/loki-values.yaml --namespace logging --create-namespace
helm upgrade --install jaeger jaegertracing/jaeger -f helm/infra-charts/jaeger-values.yaml --namespace observability
helm upgrade --install kafka bitnami/kafka -f helm/infra-charts/kafka-values.yaml --namespace data --create-namespace