#!/usr/bin/env bash
# El bootstrap de ansible/awx solo genera un PLACEHOLDER de la UI si no
# encuentra un build real. La UI de verdad vive en un repo aparte
# (ansible/ansible-ui) y hay que compilarla aparte, dentro del propio
# contenedor de control (ya trae Node 18). Tarda varios minutos. Hace
# falta repetirlo tras un "make docker-compose-build" que reconstruya la
# imagen desde cero, o si borras awx/awx/ui/build a mano.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

docker compose exec -T awx_1 bash -c "
    rm -rf /awx_devel/awx/ui/build /awx_devel/awx/ui/src/build
    cd /awx_devel && make ui
"

echo "UI compilada. Reiniciando el control node para que nginx/uwsgi recojan los nuevos estáticos..."
docker compose restart awx_1
