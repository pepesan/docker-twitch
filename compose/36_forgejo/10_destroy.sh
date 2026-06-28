#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "ATENCIÓN: esto eliminará los contenedores Y todos los datos en ./data/"
read -rp "¿Estás seguro? Escribe 'si' para confirmar: " confirm

if [ "$confirm" != "si" ]; then
  echo "Cancelado."
  exit 0
fi

echo "==> Deteniendo y eliminando contenedores..."
docker compose down --remove-orphans

echo "==> Eliminando datos de volúmenes..."
sudo rm -rf data/

echo "==> Destrucción completada."
