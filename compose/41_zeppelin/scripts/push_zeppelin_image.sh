#!/usr/bin/env bash
# Sube la imagen Zeppelin del curso a Docker Hub como pepesan/zeppelin,
# con el tag de la versión de Python que lleva dentro (detectada en la
# propia imagen ya construida, no escrita a mano) y también como "latest".
# Requiere haber ejecutado antes build_zeppelin_image.sh y tener sesión
# (`docker login`) como pepesan.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG=$(docker images --format '{{.Repository}}:{{.Tag}}' 'pepesan/zeppelin' | grep '^pepesan/zeppelin:python-' | head -n1)
if [ -z "$TAG" ]; then
    echo "No hay ninguna imagen local pepesan/zeppelin:python-* — ejecuta antes ./build_zeppelin_image.sh" >&2
    exit 1
fi

docker push "$TAG"

docker tag "$TAG" pepesan/zeppelin:latest
docker push pepesan/zeppelin:latest

echo "Publicadas: $TAG y pepesan/zeppelin:latest"
