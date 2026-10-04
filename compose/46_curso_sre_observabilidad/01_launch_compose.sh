#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d

cat <<'EOF'

URLs:
  Portal (Dashy)     http://localhost:4000
  Grafana            http://localhost:3030
  Prometheus         http://localhost:9090
  Alertmanager       http://localhost:9093
  Loki (API)         http://localhost:3100
  Tempo (API)        http://localhost:3200
  Alloy (UI)         http://localhost:12345
  Blackbox Exporter  http://localhost:9115
  hot-rod (demo app) http://localhost:8082
EOF
