#!/usr/bin/env bash
# Construye la imagen Zeppelin del curso, la verifica y la publica en Docker
# Hub como pepesan/zeppelin con tres tags que apuntan a la misma imagen:
#
#   python-X.Y     tag flotante que usa compose.yaml (ej. python-3.14)
#   X.Y.Z          versión exacta de Python que lleva dentro (ej. 3.14.8)
#   latest         alias del anterior
#
# Los tres se calculan a partir de la imagen ya construida (nunca a mano).
# La versión exacta importa: `uv venv --python 3.14` resuelve la última 3.14.x
# disponible en el momento del build, así que cambia sin tocar el Dockerfile.
#
# Antes de subir nada comprueba dentro de la imagen que Python es el esperado
# y que TODAS las librerías de zeppelin/image/requirements.txt están
# instaladas e importables; si algo falla, aborta sin publicar. La subida
# sobrescribe python-X.Y y latest, que usan los despliegues existentes.
#
# Uso:
#   ./build_push_zeppelin_image.sh            # build + verificación + push
#   ./build_push_zeppelin_image.sh --no-push  # solo build + verificación
#
# Requiere `docker login` como pepesan para el push. Ejecutar fuera de un
# escritorio Kasm: el build ocupa ~7 GB y tarda varios minutos.
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE="pepesan/zeppelin"
PUSH=true
[[ "${1:-}" == "--no-push" ]] && PUSH=false

echo ">> Construyendo imagen (zeppelin/image)..."
docker build -t "${IMAGE}:build-tmp" ./zeppelin/image

echo ">> Verificando contenido de la imagen..."
PY_FULL=$(docker run --rm --entrypoint python "${IMAGE}:build-tmp" -c \
    "import sys; print('%d.%d.%d' % sys.version_info[:3])")
PY_MINOR="${PY_FULL%.*}"

# Nombres de distribución de requirements.txt (sin comentarios ni versiones)
mapfile -t PKGS < <(sed -e 's/#.*//' -e 's/[<>=!~\[ ].*//' -e '/^$/d' zeppelin/image/requirements.txt)

docker run --rm -i --entrypoint python "${IMAGE}:build-tmp" - "${PKGS[@]}" <<'PY'
import sys, importlib.metadata as m
missing = []
for p in sys.argv[1:]:
    try:
        print("  %-18s %s" % (p, m.version(p)))
    except m.PackageNotFoundError:
        missing.append(p)
if missing:
    sys.exit("FALTAN librerías en la imagen: " + ", ".join(missing))
import anthropic  # la que más fácil es que falte; el notebook 08 la usa
PY

echo ">> Python ${PY_FULL} y ${#PKGS[@]} librerías OK"

docker tag "${IMAGE}:build-tmp" "${IMAGE}:python-${PY_MINOR}"
docker tag "${IMAGE}:build-tmp" "${IMAGE}:${PY_FULL}"
docker tag "${IMAGE}:build-tmp" "${IMAGE}:latest"
docker rmi "${IMAGE}:build-tmp" >/dev/null

if [ "$PUSH" = false ]; then
    echo "Imagen construida y verificada (sin publicar): ${IMAGE}:python-${PY_MINOR}, ${IMAGE}:${PY_FULL}, ${IMAGE}:latest"
    exit 0
fi

for TAG in "${PY_FULL}" "python-${PY_MINOR}" latest; do
    echo ">> docker push ${IMAGE}:${TAG}"
    docker push "${IMAGE}:${TAG}"
done

echo "Publicadas: ${IMAGE}:python-${PY_MINOR}, ${IMAGE}:${PY_FULL} y ${IMAGE}:latest"
