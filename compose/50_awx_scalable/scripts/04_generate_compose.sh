#!/usr/bin/env bash
# Traduce el docker-compose.yml que el propio ansible/awx genera en
# awx/tools/docker-compose/_sources/docker-compose.yml a nuestro propio
# compose.yaml (raíz del ejemplo), con el número de execution nodes que
# toque en cada momento (AWX_EXECUTION_NODE_COUNT). Se puede volver a
# ejecutar cuantas veces haga falta: siempre sobrescribe compose.yaml
# entero con el estado actual.
set -euo pipefail
cd "$(dirname "$0")/.."
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

SRC="awx/tools/docker-compose/_sources/docker-compose.yml"
if [ ! -f "$SRC" ]; then
    echo "No existe $SRC — ejecuta antes ./scripts/02_build_image.sh" >&2
    exit 1
fi

{
    echo "# Generado automáticamente por scripts/04_generate_compose.sh"
    echo "# a partir de awx/tools/docker-compose/_sources/docker-compose.yml."
    echo "# No editar a mano: los cambios se perderán en el próximo build."
    echo "# Para cambiar el número de execution nodes: AWX_EXECUTION_NODE_COUNT"
    echo "# en .env, luego ./scripts/02_build_image.sh + este script (o ./10_scale.sh <N>)."
    echo
    tail -n +2 "$SRC"
} > compose.yaml

# --- Reescritura de imagen propia (control + execution nodes) ---
# El hop (quay.io/ansible/receptor:devel) se deja con su imagen original,
# no es nuestra.
sed -i "s#image: \"ghcr.io/ansible/awx_devel:devel\"#image: \"\${AWX_IMAGE}\"#g" compose.yaml

# --- Reescritura de rutas relativas al clon ./awx ---
sed -i \
    -e 's#\.\./\.\./\.\./:/awx_devel#./awx:/awx_devel#g' \
    -e 's#\.\./\.\./docker-compose/#./awx/tools/docker-compose/#g' \
    -e 's#\.\./\.\./redis/#./awx/tools/redis/#g' \
    compose.yaml

# --- Postgres: official postgres:17 en vez del sclorg-15 por defecto ---
python3 - "$AWX_EXAMPLE_DIR/compose.yaml" "$AWX_PG_PASSWORD" <<'PYEOF'
import re, sys
path, pg_password = sys.argv[1], sys.argv[2]
text = open(path).read()

old_postgres = re.search(
    r"^  postgres:\n(?:.*\n)*?       - \"\$\{AWX_PG_PORT:-5441\}:5432\"\n",
    text,
    re.MULTILINE,
)
if not old_postgres:
    sys.exit("No se encontró el bloque 'postgres:' esperado en compose.yaml generado")

new_postgres = (
    "  postgres:\n"
    "    image: postgres:17\n"
    "    container_name: awx_postgres\n"
    "    command: >\n"
    "      postgres -c log_destination=stderr -c log_min_messages=info"
    " -c log_min_duration_statement=1000 -c max_connections=1024\n"
    "    environment:\n"
    "      POSTGRES_USER: awx\n"
    "      POSTGRES_DB: awx\n"
    f"      POSTGRES_PASSWORD: \"{pg_password}\"\n"
    "    volumes:\n"
    "      - ./volumes/awx_db:/var/lib/postgresql/data\n"
    "    networks:\n"
    "      - awx\n"
    "    ports:\n"
    "      - \"${AWX_PG_PORT:-5441}:5432\"\n"
)
text = text[: old_postgres.start()] + new_postgres + text[old_postgres.end() :]
open(path, "w").write(text)
PYEOF

# --- Puertos: usar los de .env en vez de los literales que trae la
# plantilla de ansible/awx (evita choques con otros servicios del host;
# el puerto 3000 de la UI dev, en concreto, suele estar ocupado) ---
sed -i \
    -e 's@"8013:8013"  # http@"${AWX_HTTP_PORT:-8013}:8013"  # http@' \
    -e 's@"8043:8043"  # https@"${AWX_HTTPS_PORT:-8043}:8043"  # https@' \
    -e 's@"3000:3001"  # used by the UI dev env@"${AWX_UI_DEV_PORT:-3301}:3001"  # used by the UI dev env@' \
    compose.yaml

# --- redis_socket_1 -> bind mount en ./volumes/redis_socket ---
sed -i \
    -e 's#"redis_socket_1:/var/run/redis/:rw"#"./volumes/redis_socket:/var/run/redis/:rw"#g' \
    compose.yaml

# --- Quitar volúmenes nombrados ahora huérfanos (awx_db_15, redis_socket_1) ---
python3 - "$AWX_EXAMPLE_DIR/compose.yaml" <<'PYEOF'
import re, sys
path = sys.argv[1]
text = open(path).read()
text = re.sub(r"\nvolumes:\n(?:  \S.*\n(?:    \S.*\n)*)+", "\n", text, count=1)
open(path, "w").write(text)
PYEOF

echo "compose.yaml regenerado: 1 control + ${AWX_EXECUTION_NODE_COUNT} execution nodes + hop + postgres:17 + redis."
