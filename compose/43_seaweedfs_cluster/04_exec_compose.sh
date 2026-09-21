#!/usr/bin/env bash
# Uso: ./04_exec_compose.sh <servicio> [comando]  (por defecto: sh)
# Servicios: master1, master2, master3, volume1, volume2, volume3,
# postgres, filer1, filer2, haproxy
cd "$(dirname "$0")"
SERVICIO="${1:?Uso: 04_exec_compose.sh <servicio> [comando]}"
shift
docker compose exec "$SERVICIO" "${@:-sh}"
