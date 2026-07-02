#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "ATENCIÓN: esto eliminará los contenedores Y los volúmenes forgejo_data/forgejo_db_data (todos los datos)"
read -rp "¿Estás seguro? Escribe 'si' para confirmar: " confirm

if [ "$confirm" != "si" ]; then
  echo "Cancelado."
  exit 0
fi

echo "==> Deteniendo contenedores y eliminando volúmenes..."
docker compose down --remove-orphans -v

echo "==> Destrucción completada."
