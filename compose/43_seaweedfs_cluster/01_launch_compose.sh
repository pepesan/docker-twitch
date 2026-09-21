#!/usr/bin/env bash
cd "$(dirname "$0")"

if [ ! -f .env ]; then
    echo "No existen credenciales generadas, ejecuta antes ./00_init.sh"
    exit 1
fi

docker compose up -d
docker compose ps
