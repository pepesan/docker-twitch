#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source scripts/lib_compose.sh
docker compose down --remove-orphans
echo "Contenedores eliminados; los datos de ./volumes se conservan."
