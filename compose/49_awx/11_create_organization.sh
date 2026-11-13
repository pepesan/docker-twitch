#!/usr/bin/env bash
# Localiza la organización de trabajo. AWX crea Default de serie; si se pide
# otra y no existe, se crea. Nunca se borra desde estos scripts.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
organization_id="$(find_by organizations name "$E2E_ORGANIZATION")"
if [[ -n "$organization_id" ]]; then
    printf '%s\n' "$organization_id" > "$E2E_STATE_DIR/organization_id"
    echo "Organización $E2E_ORGANIZATION reutilizada (id=$organization_id)."
else
    response="$(api_request POST /api/v2/organizations/ "$(jq -n --arg name "$E2E_ORGANIZATION" '{name:$name}')")"
    echo "Organización $E2E_ORGANIZATION creada (id=$(state_write_id organization_id "$response"))."
fi
