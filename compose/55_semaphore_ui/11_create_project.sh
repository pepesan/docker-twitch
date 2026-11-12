#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login

projects="$(api_request GET /api/projects)"
project_id="$(jq -r --arg name "$E2E_PROJECT_NAME" '[.[] | select(.name == $name) | .id] | .[0] // empty' <<<"$projects")"
if [[ -n "$project_id" ]]; then
    printf '%s\n' "$project_id" > "$E2E_STATE_DIR/project_id"
    echo "Proyecto Semaphore reutilizado: $E2E_PROJECT_NAME (id=$project_id)."
else
    payload="$(jq -nc --arg name "$E2E_PROJECT_NAME" '{name:$name,alert:false,max_parallel_tasks:1,demo:false}')"
    response="$(api_request POST /api/projects "$payload")"
    project_id="$(state_write_id project_id "$response")"
    echo "Proyecto Semaphore creado: $E2E_PROJECT_NAME (id=$project_id)."
fi
