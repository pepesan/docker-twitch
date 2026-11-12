#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
cat >&2 <<'NOTICE'
DESTRUCCIÓN mTLS: elimina contenedores, red, volúmenes Docker, data/alloy, .env y certs/.
Se perderán los datos persistidos y las claves/certificados de laboratorio.
NOTICE
read -r -p 'Escribe DESTROY para continuar: ' answer
[[ "$answer" == DESTROY ]] || { echo 'Cancelado.'; exit 1; }
docker compose --env-file ../53_monitoring/.env -f ../53_monitoring/compose.yaml -f compose.tls.yaml down --volumes --remove-orphans
rm -rf ../53_monitoring/data/alloy certs
rm -f ../53_monitoring/.env
