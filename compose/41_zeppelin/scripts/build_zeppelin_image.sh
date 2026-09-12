#!/usr/bin/env bash
# Construye la imagen Zeppelin del curso (ver ../zeppelin/image/Dockerfile)
# y la etiqueta como pepesan/zeppelin:python-<X.Y> — el mismo nombre que usa
# compose.yaml, tanto en local como al publicarla (ver push_zeppelin_image.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

docker build -t pepesan/zeppelin:build-tmp ./zeppelin/image

PY_MINOR=$(docker run --rm pepesan/zeppelin:build-tmp python3 -c "import sys; print('%d.%d' % sys.version_info[:2])")
TAG="pepesan/zeppelin:python-${PY_MINOR}"

docker tag pepesan/zeppelin:build-tmp "$TAG"
docker rmi pepesan/zeppelin:build-tmp >/dev/null

echo "Imagen construida: ${TAG}"
