#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source scripts/lib_compose.sh

docker compose config -q
docker compose up -d

printf '\nSemaphore UI: http://localhost:%s/\n' "$(. ./.env; printf '%s' "${SEMAPHORE_HTTP_PORT:-3001}")"
printf 'Usuario: %s\nContraseña: %s\n' "$(. ./.env; printf '%s' "${SEMAPHORE_ADMIN_USER:-admin}")" "${SEMAPHORE_ADMIN_PASSWORD}"
echo "La contraseña inicial de admin solo se aplica al crear el usuario por primera vez."
