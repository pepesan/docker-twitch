#!/usr/bin/env bash
set -e

# Parar si estaba corriendo
docker compose down


# Borrar directorios
sudo rm -rf  source/data
sudo rm -rf  replica/data

echo "✔ Directorios y contenedores borrados."

