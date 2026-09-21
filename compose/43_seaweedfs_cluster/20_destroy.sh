#!/usr/bin/env bash
# Borra completamente el entorno: contenedores, red, ./data (datos de
# masters/volumes/postgres) y las credenciales generadas por 00_init.sh
# (.env, filer-config/filer.toml, s3-config/s3.json, haproxy/haproxy.cfg).
# Irreversible.
cd "$(dirname "$0")"
read -r -p "Esto borrará contenedores, ./data y las credenciales generadas. ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down -v --remove-orphans
    sudo rm -rf data
    rm -f .env filer-config/filer.toml s3-config/s3.json haproxy/haproxy.cfg
else
    echo "Cancelado."
fi
