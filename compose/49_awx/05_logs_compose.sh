#!/usr/bin/env bash
# Uso: ./05_logs_compose.sh [servicio]  (awx, postgres, redis; por defecto todos)
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose logs -f "$@"
