#!/usr/bin/env bash
# Publica en Docker Hub la imagen construida por 02_build_image.sh.
# Requiere haber hecho antes "docker login" a mano con tu cuenta de
# Docker Hub (este script nunca introduce credenciales).
set -euo pipefail
cd "$(dirname "$0")/.."
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

if ! docker info 2>/dev/null | grep -qi username; then
    echo "Aviso: no se detecta sesión activa de 'docker login'. Si el push falla," >&2
    echo "ejecuta primero: docker login" >&2
fi

docker push "${AWX_IMAGE}"

echo "Imagen publicada: ${AWX_IMAGE}"
