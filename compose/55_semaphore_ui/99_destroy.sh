#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source scripts/lib_compose.sh

echo "Esto eliminará los contenedores y todos los datos persistentes de ./volumes."
read -r -p "Escribe DESTROY para confirmar: " confirmation
if [[ "$confirmation" != "DESTROY" ]]; then
    echo "Cancelado; no se ha borrado nada."
    exit 0
fi

docker compose down --remove-orphans
sudo rm -rf -- volumes
echo "Datos eliminados. .env y secrets.env se conservan; bórralos manualmente si quieres regenerar configuración y credenciales."
