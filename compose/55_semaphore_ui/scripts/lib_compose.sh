#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env || ! -f secrets.env ]]; then
    echo "Falta la configuración local. Ejecuta primero ./00_init.sh." >&2
    exit 1
fi

set -a
# shellcheck disable=SC1091
source secrets.env
set +a
