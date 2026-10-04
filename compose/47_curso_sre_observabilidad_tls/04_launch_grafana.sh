#!/usr/bin/env bash
# Módulo grafana (ver README, "Arranque por fases"). Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.grafana.yaml up -d

cat <<'EOT'

URLs:                  directa                  vía Caddy (HTTPS)
  Grafana              http://localhost:3030    https://grafana.lab.local
EOT
