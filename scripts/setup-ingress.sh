#!/usr/bin/env bash
set -euo pipefail

echo "🔗 Setting up Istio Ingress Gateway access..."

# Try to detect a reachable host:port for the Istio ingress gateway
NODE_PORT=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' || true)
REACHABLE_PORT=""
REACHABLE_DESC=""

if [[ -n "${NODE_PORT}" ]]; then
  # Try server node ports on k3d server and agents via host network
  for host in localhost 127.0.0.1; do
    if nc -z ${host} ${NODE_PORT} 2>/dev/null; then
      REACHABLE_PORT="${NODE_PORT}"
      REACHABLE_DESC="NodePort ${NODE_PORT}"
      break
    fi
  done
fi

# Fallback: port-forward the ingressgateway service locally
if [[ -z "${REACHABLE_PORT}" ]]; then
  REACHABLE_PORT=80
  REACHABLE_DESC="kubectl port-forward to ${REACHABLE_PORT}"
  echo "🔁 Starting background port-forward from local :${REACHABLE_PORT} to istio-ingressgateway:80"
  # Kill any existing forward on that port
  PF_PID=$(lsof -ti tcp:${REACHABLE_PORT} || true)
  if [[ -n "${PF_PID}" ]]; then
    kill -9 ${PF_PID} || true
  fi
  # Run port-forward in the background with nohup
  nohup kubectl -n istio-system port-forward svc/istio-ingressgateway ${REACHABLE_PORT}:80 >/tmp/ingress-pf.log 2>&1 &
  sleep 1
fi

GATEWAY_HOST="localhost:${REACHABLE_PORT}"

echo "📍 Istio Ingress Gateway available at: ${GATEWAY_HOST} (${REACHABLE_DESC})"

# Check if entries already exist in /etc/hosts
if ! grep -q "jaeger.local" /etc/hosts 2>/dev/null; then
    echo "📝 Adding DNS entries to /etc/hosts (requires sudo)..."
    
    # Add entries to /etc/hosts
    sudo tee -a /etc/hosts > /dev/null << EOF

# Quarkus Microservices Demo - Istio Ingress
127.0.0.1 jaeger.local
127.0.0.1 grafana.local
EOF
    
    echo "✅ DNS entries added to /etc/hosts"
else
    echo "✅ DNS entries already exist in /etc/hosts"
fi

echo ""
echo "🌐 Access URLs (via Istio Ingress Gateway):"
echo "   Jaeger:  http://jaeger.local:${REACHABLE_PORT}"
echo "   Grafana: http://grafana.local:${REACHABLE_PORT}"
echo ""
echo "🔧 Alternative (direct access):"
echo "   Using curl with Host header:"
echo "   curl -H 'Host: jaeger.local' http://localhost:${REACHABLE_PORT}"
echo "   curl -H 'Host: grafana.local' http://localhost:${REACHABLE_PORT}"
echo ""
echo "🧹 To remove DNS entries later:"
echo "   sudo sed -i '' '/# Quarkus Microservices Demo/,+2d' /etc/hosts"
