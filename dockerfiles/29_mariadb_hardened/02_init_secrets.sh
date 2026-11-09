#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p secrets
umask 077
for secret in root_password app_password; do
  if [[ ! -s "secrets/$secret" ]]; then
    openssl rand -hex 32 > "secrets/$secret"
    chmod 0600 "secrets/$secret"
    echo "Creado secreto local secrets/$secret (no se muestra ni se versiona)."
  else
    echo "secrets/$secret ya existe: se conserva."
  fi
done
