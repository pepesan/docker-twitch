#!/usr/bin/env bash
# Opcional: carga datos de ejemplo (organización, proyecto, inventario demo).
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose exec awx awx-manage create_preload_data
