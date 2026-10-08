#!/usr/bin/env bash
# Clona la rama de DESARROLLO (devel) del repo oficial ansible/awx en
# ./awx. Idempotente: si ya existe, actualiza (fetch + reset --hard al
# HEAD remoto de devel) en vez de limitarse a saltarse el paso, para que
# el proceso siempre recoja los últimos cambios de origen.
# Aviso oficial del propio repo: desplegar desde devel/HEAD no es
# estable, es la rama de desarrollo activo, no una release.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO_DIR="awx"
REPO_URL="https://github.com/ansible/awx.git"

if [ -d "$REPO_DIR" ]; then
    echo "Actualizando ${REPO_DIR}/ (fetch + reset --hard origin/devel)..."
    git -C "$REPO_DIR" fetch origin devel
    git -C "$REPO_DIR" reset --hard origin/devel
    # No limpiamos archivos sin seguimiento: awx/ui/build (UI compilada),
    # tools/docker-compose/_sources (config renderizada con las
    # passwords ya sincronizadas) y projects/ son productos nuestros,
    # no del repo, y los necesitamos vivos entre ejecuciones.
else
    git clone --branch devel --single-branch "$REPO_URL" "$REPO_DIR"
fi
