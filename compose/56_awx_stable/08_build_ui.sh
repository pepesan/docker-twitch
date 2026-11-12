#!/usr/bin/env bash
# El arranque de AWX solo genera un PLACEHOLDER de la UI si no encuentra un
# build real. La UI de esta versión es una aplicación React en awx/ui que se
# compila con Node dentro del propio contenedor (la imagen ya trae el Node que
# exige su Makefile): "make ui-devel" ejecuta npm ci, compila las cadenas y
# lanza webpack, y deja el marcador awx/ui/.ui-built. Tarda varios minutos.
# Hay que repetirlo tras reconstruir la imagen desde cero o si se borra
# awx/ui/build a mano.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose exec -T awx bash -c "
    cd /awx_devel
    rm -rf awx/ui/build awx/ui/.ui-built
    mkdir -p awx/ui/build/static
    make ui-devel
"
echo "UI compilada. Reiniciando el contenedor awx para que nginx/uwsgi recojan los nuevos estáticos..."
docker compose restart awx
