#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login
project_id="$(state_read project_id)"
keys="$(api_request GET "/api/project/$project_id/keys?sort=name&order=asc")"
key_name="E2E SSH $E2E_TARGET_USER@$E2E_TARGET_HOST"
key_id="$(jq -r --arg name "$key_name" '[.[] | select(.name == $name) | .id] | .[0] // empty' <<<"$keys")"
if [[ -n "$key_id" ]]; then
    printf '%s\n' "$key_id" > "$E2E_STATE_DIR/ssh_key_id"
    echo "Credencial SSH existente reutilizada (id=$key_id)."
else
    payload="$(jq -nc --arg name "$key_name" --arg login "$E2E_TARGET_USER" --rawfile private_key "$E2E_SSH_PRIVATE_KEY" '{name:$name,type:"ssh",project_id:'"$project_id"',ssh:{login:$login,private_key:$private_key,passphrase:""}}')"
    response="$(api_request POST "/api/project/$project_id/keys" "$payload")"
    key_id="$(state_write_id ssh_key_id "$response")"
    echo "Credencial SSH creada en el almacén cifrado de Semaphore (id=$key_id)."
fi
