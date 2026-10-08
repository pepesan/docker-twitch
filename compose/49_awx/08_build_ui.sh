#!/usr/bin/env bash
# El bootstrap de ansible/awx solo genera un PLACEHOLDER de la UI
# (awx/ui/build/awx/index_awx.html) si no encuentra un build real. La UI
# de verdad vive en un repo aparte (ansible/ansible-ui) y hay que
# compilarla con Node dentro del propio contenedor devel (ya trae Node
# 18, que es lo que exige su Makefile). Tarda varios minutos (clona el
# repo, npm install, webpack build). Hace falta volver a ejecutar esto
# tras un "make docker-compose-build" que reconstruya la imagen desde
# cero, o si borras awx/awx/ui/build a mano.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

docker compose exec -T awx bash -c "
    rm -rf /awx_devel/awx/ui/build /awx_devel/awx/ui/src/build
    cd /awx_devel && make ui
"

echo "UI compilada. Reiniciando el contenedor awx para que nginx/uwsgi recojan los nuevos estáticos..."
docker compose restart awx
