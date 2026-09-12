#!/usr/bin/env bash
# Uso: ./04_exec_compose.sh <servicio> [comando]  (por defecto: bash)
# Servicios disponibles: zeppelin, db, hue, adminer
cd "$(dirname "$0")"
SERVICIO="${1:?Uso: 04_exec_compose.sh <servicio> [comando]}"
shift
docker compose exec "$SERVICIO" "${@:-bash}"
