#!/bin/bash

echo "Eliminando contenedores..."
docker compose down

# Lista de volúmenes a eliminar
VOLUMES=(
  ingestion-volume-dag-airflow
  ingestion-volume-dags
  ingestion-volume-tmp
  es-data
)

echo "Eliminando volúmenes..."

for VOLUME in "${VOLUMES[@]}"; do
  if docker volume inspect "$VOLUME" >/dev/null 2>&1; then
    echo "Eliminando $VOLUME"
    docker volume rm "$VOLUME"
  else
    echo "El volumen $VOLUME no existe"
  fi
done

echo "Proceso finalizado."

