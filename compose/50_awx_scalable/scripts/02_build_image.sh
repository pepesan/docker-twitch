#!/usr/bin/env bash
# Compila la imagen de desarrollo de AWX (make docker-compose-build, que
# internamente hace "docker build -f Dockerfile.dev") y, además, renderiza
# los ficheros de configuración (SECRET_KEY, database.py, nginx.conf,
# receptor.conf de control/hop/execution...) pasando el número de nodos
# de control y de ejecución deseados. Al final re-etiqueta la imagen con
# el nombre propio que se subirá a Docker Hub.
set -euo pipefail
cd "$(dirname "$0")/.."
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

cd awx

make docker-compose-build
make docker-compose-sources \
    CONTROL_PLANE_NODE_COUNT="${AWX_CONTROL_NODE_COUNT}" \
    EXECUTION_NODE_COUNT="${AWX_EXECUTION_NODE_COUNT}"

# Fija la password que Django usará contra Postgres a la de secrets.env,
# para que coincida siempre con el servicio "postgres" de compose.yaml
# (si no, cada "make docker-compose-sources" genera una password
# aleatoria nueva).
sed -i "s/'PASSWORD': \".*\"/'PASSWORD': \"${AWX_PG_PASSWORD}\"/" tools/docker-compose/_sources/database.py

# El compose que genera AWX monta /etc/receptor/work_public_key.pem en
# cada execution node incluso con la firma de work units desactivada
# (sign_work=no, el valor por defecto que usamos) — como el fichero no
# se genera en ese caso, Docker lo crearía como directorio vacío en vez
# de fichero al montarlo. receptor no llega a abrirlo si sign_work=no,
# pero igualmente dejamos un fichero vacío real para que el bind mount
# sea limpio. Algún proceso dentro de los contenedores (receptor-hop
# corre como root) puede terminar dejando ese directorio con dueño
# root — en ese caso ya no hace falta tocarlo (el fichero ya existe) y
# simplemente lo ignoramos en vez de abortar el script.
if [ ! -e tools/docker-compose/_sources/receptor/work_public_key.pem ]; then
    touch tools/docker-compose/_sources/receptor/work_public_key.pem 2>/dev/null || true
fi

docker tag ghcr.io/ansible/awx_devel:devel "${AWX_IMAGE}"

echo "Imagen local lista: ${AWX_IMAGE}"
echo "Nodos renderizados: 1 control + ${AWX_EXECUTION_NODE_COUNT} execution + hop"
echo "Siguiente paso: ./04_generate_compose.sh (traduce el docker-compose.yml generado a nuestro compose.yaml)"
