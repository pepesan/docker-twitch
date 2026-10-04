#!/usr/bin/env bash
# Módulo proxy (ver README, "Arranque por fases"). Requiere ./00_init.sh ejecutado.
cd "$(dirname "$0")"
docker compose --env-file compose.env -f compose.proxy.yaml up -d

cat <<'EOT'

Caddy (TLS autofirmado) escuchando en los puertos CADDY_HTTP_PORT/CADDY_HTTPS_PORT de compose.env.
EOT
