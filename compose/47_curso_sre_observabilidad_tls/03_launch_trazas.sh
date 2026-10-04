#!/usr/bin/env bash
# Módulo trazas (ver README, "Arranque por fases"). Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.trazas.yaml up -d

cat <<'EOT'

URLs:                  directa                  vía Caddy (HTTPS, usuario curso)
  Tempo (API)          http://localhost:3200    https://tempo.lab.local
  OTLP (collector)     localhost:4317 (gRPC) / localhost:4318 (HTTP)   (sin vhost)
EOT
