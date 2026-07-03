#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Deteniendo y eliminando los contenedores (incluye el perfil 'monitoring')..."
docker compose --profile monitoring down --remove-orphans

echo "==> Destrucción completada."
