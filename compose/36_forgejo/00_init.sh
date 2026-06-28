#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Creando directorios de datos..."
mkdir -p data/forgejo data/postgres

echo "==> Ajustando permisos..."
sudo chown -R 1000:1000 data/forgejo
sudo chown -R 999:999 data/postgres

if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "==> .env creado desde .env.example — edita la contraseña antes de lanzar"
  else
    echo "WARN: no existe .env ni .env.example"
  fi
else
  echo "==> .env ya existe, sin cambios"
fi

echo "==> Listo. Ejecuta ./01_launch.sh para arrancar."
