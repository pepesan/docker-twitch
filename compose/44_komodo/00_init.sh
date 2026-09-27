#!/usr/bin/env bash
# Crea las carpetas de datos persistentes y genera compose.env con secretos
# nuevos (a partir de compose.env.template) si no existe todavía. Ejecutar
# una vez antes del primer 01_launch_compose.sh y cada vez que se borre con
# 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p mongo-data mongo-config keys backups

if [ -f compose.env ]; then
    echo "compose.env ya existe, no se regenera (borra el fichero si quieres secretos nuevos)."
else
    db_password=$(openssl rand -hex 16)
    admin_password=$(openssl rand -hex 12)
    webhook_secret=$(openssl rand -hex 32)
    jwt_secret=$(openssl rand -hex 32)
    sed -e "s/__KOMODO_DATABASE_PASSWORD__/${db_password}/" \
        -e "s/__KOMODO_INIT_ADMIN_PASSWORD__/${admin_password}/" \
        -e "s/__KOMODO_WEBHOOK_SECRET__/${webhook_secret}/" \
        -e "s/__KOMODO_JWT_SECRET__/${jwt_secret}/" \
        compose.env.template > compose.env
    echo "compose.env generado. Credenciales iniciales:"
    echo "  admin username: admin"
    echo "  admin password: ${admin_password}"
fi
