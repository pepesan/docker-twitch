#!/usr/bin/env bash
# Uso: ./03_logs_compose.sh [servicio]
cd "$(dirname "$0")"
docker compose logs -f "$@"
