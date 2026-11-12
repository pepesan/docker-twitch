#!/usr/bin/env bash
# Borra completamente el entorno: contenedores, ./volumes (datos de
# postgres y socket de redis) y el directorio awx clonado (repo +
# configuración renderizada). No borra la imagen ya subida a Docker Hub.
# Irreversible.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
read -r -p "Esto borrará los contenedores, ./volumes y el directorio awx clonado. ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    docker compose down --remove-orphans
    sudo rm -rf awx volumes
    echo "secrets.env se ha conservado (mismas credenciales en el próximo ./00_init.sh)."
    echo "Bórralo a mano si quieres que se generen contraseñas nuevas."
else
    echo "Cancelado."
fi
