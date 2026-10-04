#!/usr/bin/env bash
# Borra completamente el entorno: contenedores, datos (mongo-data, mongo-config,
# keys, backups) y compose.env (los secretos generados). Irreversible.
cd "$(dirname "$0")"
read -r -p "Esto borrará los contenedores, los datos de Komodo (mongo-data, mongo-config, keys, backups) y compose.env (secretos). ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down -v --remove-orphans
    sudo rm -rf data projects builds
else
    echo "Cancelado."
fi
