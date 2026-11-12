#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "Creado .env desde .env.example. Puedes cambiar el puerto antes de arrancar."
fi
chmod 600 .env

if [[ ! -f secrets.env ]]; then
    umask 077
    db_password="$(openssl rand -hex 24)"
    admin_password="$(openssl rand -hex 24)"
    encryption_key="$(head -c 32 /dev/urandom | base64 | tr -d '\n')"
    cat > secrets.env <<EOF
SEMAPHORE_DB_PASSWORD=${db_password}
SEMAPHORE_ADMIN_PASSWORD=${admin_password}
SEMAPHORE_ACCESS_KEY_ENCRYPTION=${encryption_key}
EOF
    chmod 600 secrets.env
    echo "Credenciales y clave de cifrado generadas en secrets.env (modo 0600)."
else
    chmod 600 secrets.env
    echo "Se conservan los secretos existentes en secrets.env."
fi

mkdir -p volumes/postgres

set -a
# shellcheck disable=SC1091
source secrets.env
set +a
printf 'Admin Semaphore: %s / %s\n' "$(. ./.env; printf '%s' "${SEMAPHORE_ADMIN_USER:-admin}")" "${SEMAPHORE_ADMIN_PASSWORD}"
printf 'Base de datos: usuario semaphore / password almacenada en secrets.env\n'
printf 'URL local: http://localhost:%s/\n' "$(. ./.env; printf '%s' "${SEMAPHORE_HTTP_PORT:-3001}")"
