#!/usr/bin/env bash
# Orquesta la preparación completa: genera las contraseñas (si no
# existen), clona ansible/awx (rama devel) y compila la imagen de
# desarrollo. No instala software del sistema ni publica nada en Docker
# Hub (ver scripts/00_install_prerequisites.sh y scripts/03_push_image.sh
# para eso).
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR

if [ ! -f secrets.env ]; then
    echo "Generando secrets.env con contraseñas aleatorias..."
    cat > secrets.env <<EOF
AWX_PG_PASSWORD=$(openssl rand -hex 16)
AWX_ADMIN_PASSWORD=$(openssl rand -hex 12)
EOF
    chmod 600 secrets.env
fi

source scripts/lib_load_env.sh

mkdir -p volumes/awx_db volumes/redis_socket

./scripts/01_clone_awx_devel.sh
./scripts/02_build_image.sh

echo
echo "=== Credenciales generadas en ./secrets.env ==="
echo "Admin AWX  -> usuario: admin / password: ${AWX_ADMIN_PASSWORD}"
echo "Postgres   -> usuario: awx   / password: ${AWX_PG_PASSWORD}"
echo "(también puedes verlas en cualquier momento con: cat secrets.env)"
