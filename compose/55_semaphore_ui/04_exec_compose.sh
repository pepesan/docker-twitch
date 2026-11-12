#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source scripts/lib_compose.sh
if [[ $# -eq 0 ]]; then
    echo "Uso: ./04_exec_compose.sh <comando> [argumentos...]" >&2
    exit 2
fi
docker compose exec semaphore "$@"
