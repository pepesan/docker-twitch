#!/usr/bin/env bash
# Crea (o reutiliza) el inventario con los grupos que usan los playbooks
# (ubuntu para 03_servidorweb y docker para 14_docker) y el host del destino.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
organization_id="$(state_read organization_id)"
inventory_id="$(find_by inventories name "$E2E_INVENTORY_NAME")"

if [[ -n "$inventory_id" ]]; then
    printf '%s\n' "$inventory_id" > "$E2E_STATE_DIR/inventory_id"
    echo "Inventario $E2E_INVENTORY_NAME reutilizado (id=$inventory_id)."
else
    response="$(api_request POST /api/v2/inventories/ "$(jq -n --arg name "$E2E_INVENTORY_NAME" --argjson organization "$organization_id" \
        '{name:$name,description:"Máquina LXD del laboratorio",organization:$organization}')")"
    inventory_id="$(state_write_id inventory_id "$response")"
    echo "Inventario $E2E_INVENTORY_NAME creado (id=$inventory_id)."
fi

# Host: ansible_host indica a Ansible la dirección de conexión.
host_id="$(find_by hosts name "$E2E_TARGET_NAME" "inventory=$inventory_id")"
if [[ -z "$host_id" ]]; then
    response="$(api_request POST "/api/v2/inventories/$inventory_id/hosts/" "$(jq -n --arg name "$E2E_TARGET_NAME" --arg ip "$E2E_TARGET_HOST" \
        '{name:$name,description:"Destino del laboratorio",variables:("ansible_host: " + $ip + "\n")}')")"
    host_id="$(jq -er '.id | tostring' <<<"$response")"
    echo "Host $E2E_TARGET_NAME creado (id=$host_id)."
else
    api_request PATCH "/api/v2/hosts/$host_id/" "$(jq -n --arg ip "$E2E_TARGET_HOST" '{variables:("ansible_host: " + $ip + "\n")}')" >/dev/null
    echo "Host $E2E_TARGET_NAME reutilizado (id=$host_id); ansible_host sincronizado con e2e.env."
fi
printf '%s\n' "$host_id" > "$E2E_STATE_DIR/host_id"

# Grupos: ubuntu (03_servidorweb) y docker (14_docker). El host pertenece a ambos.
for group_name in ubuntu docker; do
    group_id="$(find_by groups name "$group_name" "inventory=$inventory_id")"
    if [[ -z "$group_id" ]]; then
        response="$(api_request POST "/api/v2/inventories/$inventory_id/groups/" "$(jq -n --arg name "$group_name" '{name:$name}')")"
        group_id="$(jq -er '.id | tostring' <<<"$response")"
        echo "Grupo $group_name creado (id=$group_id)."
    else
        echo "Grupo $group_name reutilizado (id=$group_id)."
    fi
    api_request POST "/api/v2/groups/$group_id/hosts/" "$(jq -n --argjson id "$host_id" '{id:$id}')" >/dev/null
    printf '%s\n' "$group_id" > "$E2E_STATE_DIR/group_${group_name}_id"
done
echo "Inventario $E2E_INVENTORY_NAME: host $E2E_TARGET_NAME en los grupos ubuntu y docker."
