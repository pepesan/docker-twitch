#!/usr/bin/env bash
# Opcional: carga datos de ejemplo (organización, proyecto, inventario,
# "Demo Job Template" sobre ansible-tower-samples). Ya se carga sola en
# el primer arranque; este script sirve para repetirlo a mano.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose exec awx_1 awx-manage create_preload_data
