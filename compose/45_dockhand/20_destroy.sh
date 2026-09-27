#!/usr/bin/env bash
# Borra completamente el entorno: contenedor y datos (./data). Irreversible.
cd "$(dirname "$0")"
read -r -p "Esto borrará el contenedor y los datos de ./data. ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down -v --remove-orphans
    sudo rm -rf data
else
    echo "Cancelado."
fi
