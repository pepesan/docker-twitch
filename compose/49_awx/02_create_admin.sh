#!/usr/bin/env bash
# El bootstrap de ansible/awx ya crea el usuario "admin" al arrancar el
# contenedor, pero sin password usable. Este script fija la contraseña
# generada en secrets.env (AWX_ADMIN_PASSWORD) con "awx-manage changepassword".
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

docker compose exec -T awx awx-manage changepassword admin <<EOF
${AWX_ADMIN_PASSWORD}
${AWX_ADMIN_PASSWORD}
EOF

echo "Login: admin / ${AWX_ADMIN_PASSWORD}"
