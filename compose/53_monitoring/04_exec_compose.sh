#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if (($# == 0)); then
  echo 'Uso: 04_exec_compose.sh SERVICIO [COMANDO...]' >&2
  exit 2
fi
docker compose exec "$@"
