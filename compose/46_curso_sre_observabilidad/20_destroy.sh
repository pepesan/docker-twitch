#!/usr/bin/env bash
# Borra completamente el entorno: contenedores, todos los datos
# (./volumes/<servicio>/data de cada servicio) y compose.env (la password
# generada). Irreversible.
cd "$(dirname "$0")"
read -r -p "Esto borrará los contenedores, TODOS los datos (métricas, logs, trazas, dashboards) y compose.env. ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down -v --remove-orphans
    sudo rm -rf volumes
    rm -f compose.env
else
    echo "Cancelado."
fi
