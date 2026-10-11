#!/usr/bin/env bash
# Borra el entorno: contenedor, datos de Sencho (./data) y los stacks creados
# desde la UI (se conserva el stack de ejemplo versionado hola-nginx).
# Irreversible.
cd "$(dirname "$0")"
read -r -p "Esto borrará el contenedor, ./data y los stacks creados en Sencho. ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down -v --remove-orphans
    sudo rm -rf data
    sudo find stacks -mindepth 1 -maxdepth 1 ! -name hola-nginx -exec rm -rf {} +
else
    echo "Cancelado."
fi
