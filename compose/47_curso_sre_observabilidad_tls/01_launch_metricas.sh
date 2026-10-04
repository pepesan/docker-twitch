#!/usr/bin/env bash
# Módulo metricas (ver README, "Arranque por fases"). Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.metricas.yaml up -d

cat <<'EOT'

URLs:                  directa                  vía Caddy (HTTPS, usuario curso)
  Prometheus           http://localhost:9090    https://prometheus.lab.local
  Alertmanager         http://localhost:9093    https://alertmanager.lab.local
  Blackbox Exporter    http://localhost:9115    (sin vhost)
  Node Exporter        http://localhost:9100    (sin vhost)
EOT
