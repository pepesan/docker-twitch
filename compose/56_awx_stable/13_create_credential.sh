#!/usr/bin/env bash
# Crea (o reutiliza) la credencial de tipo Machine con la clave SSH del destino.
# AWX guarda la clave cifrada y no la vuelve a mostrar. La clave se lee del
# fichero indicado en e2e.env y nunca se imprime.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
organization_id="$(state_read organization_id)"
credential_id="$(find_by credentials name "$E2E_CREDENTIAL_NAME")"

if [[ -n "$credential_id" ]]; then
    printf '%s\n' "$credential_id" > "$E2E_STATE_DIR/credential_id"
    echo "Credencial Machine $E2E_CREDENTIAL_NAME reutilizada (id=$credential_id)."
    exit 0
fi

machine_type_id="$(find_by credential_types name Machine 'kind=ssh')"
[[ -n "$machine_type_id" ]] || { echo 'AWX no tiene el tipo de credencial Machine.' >&2; exit 1; }

# Si la clave tuviera passphrase habría que añadir "ssh_key_unlock"; la clave del
# laboratorio no la tiene, así que no se envía ese campo.
payload="$(jq -n \
    --arg name "$E2E_CREDENTIAL_NAME" \
    --argjson organization "$organization_id" \
    --argjson type "$machine_type_id" \
    --arg username "$E2E_TARGET_USER" \
    --rawfile key "$E2E_SSH_PRIVATE_KEY" \
    --arg become "$E2E_BECOME" \
    '{name:$name,description:"Acceso SSH al destino del laboratorio",organization:$organization,credential_type:$type,
      inputs:({username:$username,ssh_key_data:$key} + (if $become == "true" then {become_method:"sudo"} else {} end))}')"
response="$(api_request POST /api/v2/credentials/ "$payload")"
echo "Credencial Machine $E2E_CREDENTIAL_NAME creada (id=$(state_write_id credential_id "$response"))."
