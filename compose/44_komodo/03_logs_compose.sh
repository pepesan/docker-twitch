#!/usr/bin/env bash
# Uso: ./03_logs_compose.sh [servicio]  (mongo, core o periphery; por defecto todos)
cd "$(dirname "$0")"
docker compose --env-file compose.env logs -f "$@"
