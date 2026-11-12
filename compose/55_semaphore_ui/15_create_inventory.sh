#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login
project_id="$(state_read project_id)"
ssh_key_id="$(state_read ssh_key_id)"
inventories="$(api_request GET "/api/project/$project_id/inventory?sort=name&order=asc")"
inventory_name='LXC Ubuntu 26.04 E2E'
inventory_id="$(jq -r --arg name "$inventory_name" '[.[] | select(.name == $name) | .id] | .[0] // empty' <<<"$inventories")"
inventory_content="$(printf '[ubuntu]\n%s ansible_user=%s\n\n[webservers]\n%s ansible_user=%s\n\n[docker]\n%s ansible_user=%s\n' "$E2E_TARGET_HOST" "$E2E_TARGET_USER" "$E2E_TARGET_HOST" "$E2E_TARGET_USER" "$E2E_TARGET_HOST" "$E2E_TARGET_USER")"
if [[ -n "$inventory_id" ]]; then
    printf '%s\n' "$inventory_id" > "$E2E_STATE_DIR/inventory_id"
    echo "Inventario existente reutilizado: $inventory_name (id=$inventory_id)."
else
    payload="$(jq -nc --arg name "$inventory_name" --arg inventory "$inventory_content" --argjson project_id "$project_id" --argjson ssh_key_id "$ssh_key_id" '{name:$name,type:"static",project_id:$project_id,inventory:$inventory,ssh_key_id:$ssh_key_id}')"
    response="$(api_request POST "/api/project/$project_id/inventory" "$payload")"
    inventory_id="$(state_write_id inventory_id "$response")"
    echo "Inventario estático creado para $E2E_TARGET_HOST como $E2E_TARGET_USER (id=$inventory_id)."
fi
