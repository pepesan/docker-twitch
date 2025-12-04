#!/usr/bin/env bash
set -e

IMAGE_NAME="pepesan/vite-vue-app:latest"
CONTAINER_NAME="vite-vue-app"
HOST_PORT=8081   # Puerto en tu máquina
CONTAINER_PORT=80

echo ">>> Construyendo la imagen Docker: $IMAGE_NAME ..."
docker build -t "$IMAGE_NAME" .

echo ">>> Eliminando contenedor anterior (si existe)..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo ">>> Lanzando contenedor..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$HOST_PORT":"$CONTAINER_PORT" \
  "$IMAGE_NAME"

echo ">>> Aplicación levantada en: http://localhost:$HOST_PORT"
