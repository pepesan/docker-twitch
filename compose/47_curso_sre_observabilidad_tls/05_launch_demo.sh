#!/usr/bin/env bash
# Módulo demo (ver README, "Arranque por fases"). Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.demo.yaml up -d

cat <<'EOT'

URLs:                  directa                  vía Caddy (HTTPS, usuario curso)
  hot-rod (demo app)   http://localhost:8082    https://hotrod.lab.local
EOT
