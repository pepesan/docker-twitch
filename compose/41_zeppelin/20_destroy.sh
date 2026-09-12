#!/usr/bin/env bash
# Borra completamente el entorno de laboratorio: contenedores, redes y
# volúmenes (datos de la BBDD, notebooks de Zeppelin, etc.). Irreversible.
cd "$(dirname "$0")"
read -r -p "Esto borrará contenedores y volúmenes de datos. ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down -v --remove-orphans
else
    echo "Cancelado."
fi
