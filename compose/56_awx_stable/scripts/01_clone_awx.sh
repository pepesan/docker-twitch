#!/usr/bin/env bash
# Clona el repo oficial ansible/awx en ./awx y deja el árbol en el tag
# publicado indicado por AWX_REF (.env). A diferencia de un entorno sobre
# la rama devel, el código no cambia entre ejecuciones: siempre es el de
# esa versión. Idempotente: si ./awx ya existe, solo recoge los tags y
# vuelve a situarse en AWX_REF.
set -euo pipefail
cd "$(dirname "$0")/.."
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
REPO_DIR="awx"
REPO_URL="https://github.com/ansible/awx.git"
: "${AWX_REF:?Define AWX_REF en .env (por ejemplo 24.6.1)}"
if [ -d "$REPO_DIR/.git" ]; then
    echo "Actualizando ${REPO_DIR}/ y situándolo en el tag ${AWX_REF}..."
    git -C "$REPO_DIR" fetch --tags origin
else
    git clone --no-checkout "$REPO_URL" "$REPO_DIR"
fi
git -C "$REPO_DIR" rev-parse --verify --quiet "refs/tags/${AWX_REF}" >/dev/null \
    || { echo "El tag ${AWX_REF} no existe en ansible/awx." >&2; exit 1; }
# --force: se descartan cambios locales en ficheros versionados. No se
# limpian los ficheros sin seguimiento: awx/awx/ui/build (UI compilada),
# tools/docker-compose/_sources (config renderizada) y projects/ son
# productos de este ejemplo y deben sobrevivir entre ejecuciones.
git -C "$REPO_DIR" checkout --force --detach "refs/tags/${AWX_REF}"
echo "ansible/awx en $(git -C "$REPO_DIR" describe --tags --exact-match HEAD) ($(git -C "$REPO_DIR" rev-parse --short HEAD))"

# Ajuste de reproducibilidad (no toca el código de AWX): el Dockerfile de
# algunas releases fija "openssl-3.0.7", un paquete que el repositorio actual
# de CentOS Stream 9 ya no ofrece y hace fallar "dnf install". Se instala la
# versión disponible. Se vuelve a aplicar en cada ejecución porque el
# checkout anterior restaura el fichero original.
DOCKERFILE_TPL="${REPO_DIR}/tools/ansible/roles/dockerfile/templates/Dockerfile.j2"
if grep -q 'openssl-3\.0\.7' "$DOCKERFILE_TPL"; then
    sed -i 's/openssl-3\.0\.7/openssl/' "$DOCKERFILE_TPL"
    echo "Ajustado ${DOCKERFILE_TPL}: openssl-3.0.7 -> openssl"
fi

# Dependencias instaladas desde la rama devel de otros repos: se fijan al
# commit vigente en la fecha de la release (scripts/pins/<AWX_REF>.txt) para
# que la construcción sea reproducible. Sin este fichero no se aplica nada.
PINS_FILE="scripts/pins/${AWX_REF}.txt"
REQ_GIT="${REPO_DIR}/requirements/requirements_git.txt"
if [ -f "$PINS_FILE" ]; then
    while read -r name sha; do
        case "$name" in ''|'#'*) continue ;; esac
        sed -i -E "s#(github\\.com/ansible/${name}(\\.git)?)@devel#\\1@${sha}#" "$REQ_GIT"
    done < "$PINS_FILE"
    echo "Dependencias git fijadas según ${PINS_FILE}:"
    grep -E '@[0-9a-f]{40}' "$REQ_GIT" | sed 's/^/  /'
fi
