#!/usr/bin/env bash
# Crea las carpetas de datos persistentes en ./volumes con el propietario
# correcto para cada contenedor (evita errores de permisos al montarlas
# como bind mount). Ejecutar una vez antes del primer 01_launch_compose.sh
# y cada vez que se borren las carpetas con 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p volumes/db volumes/zeppelin/notebook volumes/zeppelin/logs zeppelin/ejemplos

# postgres corre como uid:gid 999:999 dentro del contenedor
docker run --rm -v "$(pwd)/volumes/db:/data" busybox chown -R 999:999 /data

# zeppelin corre como uid 1000, gid 0 dentro del contenedor
docker run --rm -v "$(pwd)/volumes/zeppelin:/data" busybox chown -R 1000:0 /data
docker run --rm -v "$(pwd)/zeppelin/ejemplos:/data" busybox chown -R 1000:0 /data
