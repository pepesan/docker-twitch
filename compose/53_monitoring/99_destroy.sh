#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
cat >&2 <<'NOTICE'
DESTRUCCIÓN HTTP: elimina contenedores, red, volúmenes Docker, data/alloy y .env.
Se perderán las métricas, logs, dashboards/datos de Grafana y el estado Alloy.
NOTICE
read -r -p 'Escribe DESTROY para continuar: ' answer
[[ "$answer" == DESTROY ]] || { echo 'Cancelado.'; exit 1; }
docker compose down --volumes --remove-orphans
rm -rf data/alloy
rm -f .env
