#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
image='docker-twitch-mariadb-hardened:11.8.9-1'
docker build --pull --tag "$image" .
echo "Imagen local creada: $image"
