#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login
project_id="$(state_read project_id)"
user_id="$(state_read user_id)"
repository_id="$(state_read repository_id)"
inventory_id="$(state_read inventory_id)"
ssh_key_id="$(state_read ssh_key_id)"

project="$(api_request GET "/api/project/$project_id/")"
user="$(api_request GET "/api/users/$user_id/")"
repository="$(api_request GET "/api/project/$project_id/repositories/$repository_id")"
inventory="$(api_request GET "/api/project/$project_id/inventory/$inventory_id")"
keys="$(api_request GET "/api/project/$project_id/keys?sort=name&order=asc")"
key="$(jq -ce --argjson id "$ssh_key_id" '.[] | select(.id == $id)' <<<"$keys")"
templates="$(api_request GET "/api/project/$project_id/templates?sort=name&order=asc")"

[[ "$(jq -r '.name' <<<"$project")" == "$E2E_PROJECT_NAME" ]]
[[ "$(jq -r '.username' <<<"$user")" == "$E2E_USER_LOGIN" ]]
[[ "$(jq -r '.git_url' <<<"$repository")" == "$E2E_REPOSITORY_URL" ]]
[[ "$(jq -r '.ssh_key_id' <<<"$inventory")" == "$ssh_key_id" ]]
[[ "$(jq -r '.type' <<<"$key")" == ssh ]]
[[ "$(jq 'length' <<<"$templates")" -ge 8 ]]

printf 'Preflight OK: proyecto=%s, usuario=%s, destino=%s@%s, %s plantillas.\n' \
    "$project_id" "$E2E_USER_LOGIN" "$E2E_TARGET_USER" "$E2E_TARGET_HOST" "$(jq 'length' <<<"$templates")"
echo 'La primera tarea de instalación probará la autenticación SSH efectiva desde Semaphore.'
