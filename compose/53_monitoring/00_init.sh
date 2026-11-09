#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  umask 077
  printf 'HOST_LABEL=%s\nALLOY_UID=%s\nALLOY_GID=%s\nGRAFANA_ADMIN_PASSWORD=%s\n' \
    "$(hostname)" "$(id -u)" "$(id -g)" "$(openssl rand -hex 24)" > .env
  echo 'Creado .env con credenciales locales; no se muestra ni se versiona.'
else
  echo '.env existente: se conserva.'
fi
mkdir -p data/alloy
