#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login
project_id="$(state_read project_id)"
repositories="$(api_request GET "/api/project/$project_id/repositories?sort=name&order=asc")"
repository_name='ejemplos-ansible'
repository_id="$(jq -r --arg name "$repository_name" --arg url "$E2E_REPOSITORY_URL" '[.[] | select(.name == $name and .git_url == $url) | .id] | .[0] // empty' <<<"$repositories")"
keys="$(api_request GET "/api/project/$project_id/keys?sort=name&order=asc")"
none_key_id="$(jq -er '.[] | select(.name == "None" and .type == "none") | .id' <<<"$keys")"
if [[ -n "$repository_id" ]]; then
    printf '%s\n' "$repository_id" > "$E2E_STATE_DIR/repository_id"
    echo "Repositorio existente reutilizado: $repository_name (id=$repository_id)."
else
    payload="$(jq -nc --arg name "$repository_name" --arg url "$E2E_REPOSITORY_URL" --arg branch "$E2E_REPOSITORY_BRANCH" --argjson project_id "$project_id" --argjson ssh_key_id "$none_key_id" '{name:$name,git_url:$url,git_branch:$branch,project_id:$project_id,ssh_key_id:$ssh_key_id,monorepo:false}')"
    response="$(api_request POST "/api/project/$project_id/repositories" "$payload")"
    repository_id="$(state_write_id repository_id "$response")"
    echo "Repositorio Git creado en Semaphore (id=$repository_id, rama=$E2E_REPOSITORY_BRANCH)."
fi
