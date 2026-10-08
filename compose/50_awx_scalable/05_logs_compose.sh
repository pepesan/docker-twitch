#!/usr/bin/env bash
# Uso: ./05_logs_compose.sh [servicio]  (awx_1, postgres, redis_1,
# receptor-hop, receptor-1..N; por defecto todos)
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose logs -f "$@"
