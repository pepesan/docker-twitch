#!/usr/bin/env bash
# Uso: ./04_exec_compose.sh <servicio> [comando]  (por defecto: sh)
cd "$(dirname "$0")"
servicio="${1:?Uso: ./04_exec_compose.sh <servicio> [comando]}"
shift || true
docker compose --env-file compose.env exec "$servicio" "${@:-sh}"
