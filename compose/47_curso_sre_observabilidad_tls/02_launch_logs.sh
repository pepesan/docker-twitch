#!/usr/bin/env bash
# Módulo logs (ver README, "Arranque por fases"). Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.logs.yaml up -d

cat <<'EOT'

URLs:                  directa                  vía Caddy (HTTPS, usuario curso)
  Loki (API)           http://localhost:3100    https://loki.lab.local
  Alloy (UI)           http://localhost:12345   https://alloy.lab.local
EOT
