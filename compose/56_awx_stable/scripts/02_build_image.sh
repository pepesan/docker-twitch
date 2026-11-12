#!/usr/bin/env bash
# Compila la imagen de AWX del tag AWX_REF (make docker-compose-build, que
# internamente hace "docker build -f Dockerfile.dev") y renderiza los
# ficheros de configuración (SECRET_KEY, database.py, nginx.conf,
# receptor.conf...) que el compose.yaml de este ejemplo monta como
# volúmenes (make docker-compose-sources). Al final re-etiqueta la imagen
# con el nombre propio que se subirá a Docker Hub.
set -euo pipefail
cd "$(dirname "$0")/.."
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
cd awx
# COMPOSE_TAG fija el nombre de la imagen; sin él se usaría el nombre de la
# rama, que en un checkout de tag (HEAD desacoplado) sería "HEAD".
make docker-compose-build COMPOSE_TAG="${AWX_REF}"
make docker-compose-sources COMPOSE_TAG="${AWX_REF}"
# Fija la password que Django usará contra Postgres a la de secrets.env,
# para que coincida siempre con el servicio "postgres" de compose.yaml (si
# no, cada "make docker-compose-sources" genera una password aleatoria nueva).
sed -i "s/'PASSWORD': \".*\"/'PASSWORD': \"${AWX_PG_PASSWORD}\"/" tools/docker-compose/_sources/database.py
docker tag "ghcr.io/ansible/awx_devel:${AWX_REF}" "${AWX_IMAGE}"
echo "Imagen local lista: ${AWX_IMAGE}"
echo "Para publicarla en Docker Hub: ./scripts/03_push_image.sh"
