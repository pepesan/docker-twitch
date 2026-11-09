#!/usr/bin/env bash
set -euo pipefail
cat >&2 <<'NOTICE'
Esto elimina el contenedor, el volumen persistente mariadb_hardened_data y secretos locales.
La base de datos y sus credenciales se perderán de forma irreversible.
NOTICE
read -r -p 'Escribe DESTROY para continuar: ' answer
[[ "$answer" == DESTROY ]] || { echo 'Cancelado.'; exit 1; }
docker rm --force mariadb-hardened >/dev/null 2>&1 || true
docker volume rm mariadb_hardened_data >/dev/null 2>&1 || true
rm -rf "$(dirname "$0")/secrets"
