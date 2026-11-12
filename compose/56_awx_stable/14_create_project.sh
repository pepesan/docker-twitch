#!/usr/bin/env bash
# Crea (o reutiliza) el proyecto Git y espera a que AWX lo sincronice.
# El repositorio es público: no hace falta credencial de control de versiones.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
organization_id="$(state_read organization_id)"
project_id="$(find_by projects name "$E2E_PROJECT_NAME")"

if [[ -n "$project_id" ]]; then
    printf '%s\n' "$project_id" > "$E2E_STATE_DIR/project_id"
    echo "Proyecto $E2E_PROJECT_NAME reutilizado (id=$project_id)."
    # Se vuelve a sincronizar para recoger cambios nuevos del repositorio.
    update="$(api_request POST "/api/v2/projects/$project_id/update/" '{}')"
    wait_job project_updates "$(jq -er '.project_update | tostring' <<<"$update")" 'Actualización del proyecto'
    exit 0
else
    payload="$(jq -n \
        --arg name "$E2E_PROJECT_NAME" \
        --argjson organization "$organization_id" \
        --arg url "$E2E_REPOSITORY_URL" \
        --arg branch "$E2E_REPOSITORY_BRANCH" \
        '{name:$name,description:"Playbooks de ejemplos-ansible",organization:$organization,scm_type:"git",scm_url:$url,scm_branch:$branch,scm_update_on_launch:false}')"
    response="$(api_request POST /api/v2/projects/ "$payload")"
    project_id="$(state_write_id project_id "$response")"
    echo "Proyecto $E2E_PROJECT_NAME creado (id=$project_id)."
fi

wait_project_sync "$project_id"
