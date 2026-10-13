#!/bin/bash

echo "Eliminando contenedores y volúmenes..."
docker compose down -v

# Datos de MySQL (bind mount, propiedad del usuario mysql del contenedor)
if [ -d docker-volume/db-data ]; then
  echo "Eliminando docker-volume/db-data"
  docker run --rm -v "$PWD/docker-volume:/data" alpine rm -rf /data/db-data
fi

echo "Proceso finalizado."
