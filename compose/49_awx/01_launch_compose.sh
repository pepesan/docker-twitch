#!/usr/bin/env bash
# Levanta el entorno con el compose.yaml propio de este ejemplo (awx +
# redis + postgres). La primera vez tarda varios minutos: migraciones de
# base de datos y bootstrap de desarrollo dentro del contenedor awx.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

docker compose up -d

echo
echo "URL: https://localhost:${AWX_HTTPS_PORT}/"
echo "Credenciales (ya en ./secrets.env):"
echo "  admin / ${AWX_ADMIN_PASSWORD:-<ejecuta ./00_init.sh primero>}"
echo "Falta: ./02_create_admin.sh (fija la password del admin) y, si es la"
echo "primera vez, ./08_build_ui.sh (compila la UI real)."
