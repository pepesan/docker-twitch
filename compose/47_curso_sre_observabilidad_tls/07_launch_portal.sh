#!/usr/bin/env bash
# Módulo portal Dashy. Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.portal.yaml up -d

cat <<'EOT'

URLs:                  directa                  vía Caddy (HTTPS, usuario curso)
  Portal (Dashy)       http://localhost:4000    https://portal.lab.local / https://lab.local
EOT
