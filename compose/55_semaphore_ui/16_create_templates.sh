#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login
project_id="$(state_read project_id)"
inventory_id="$(state_read inventory_id)"
repository_id="$(state_read repository_id)"

create_template() {
    local name="$1" working_directory="$2" playbook="$3" templates template_id payload response
    templates="$(api_request GET "/api/project/$project_id/templates?sort=name&order=asc")"
    template_id="$(jq -r --arg name "$name" '[.[] | select(.name == $name) | .id] | .[0] // empty' <<<"$templates")"
    payload="$(jq -nc --arg name "$name" --arg working_directory "$working_directory" --arg playbook "$playbook" --argjson project_id "$project_id" --argjson inventory_id "$inventory_id" --argjson repository_id "$repository_id" '{name:$name,project_id:$project_id,inventory_id:$inventory_id,repository_id:$repository_id,app:"ansible",type:"deploy",playbook:$playbook,working_directory:$working_directory,arguments:"[]",allow_override_args_in_task:false}')"
    if [[ -n "$template_id" ]]; then
        payload="$(jq --argjson template_id "$template_id" '. + {id:$template_id}' <<<"$payload")"
        api_request PUT "/api/project/$project_id/templates/$template_id" "$payload" >/dev/null
        echo "Plantilla actualizada: $name (id=$template_id)."
    else
        response="$(api_request POST "/api/project/$project_id/templates" "$payload")"
        template_id="$(jq -er '.id' <<<"$response")"
        printf '%s\n' "$template_id" > "$E2E_STATE_DIR/template_${template_id}"
        echo "Plantilla creada: $name (id=$template_id)."
    fi
}

create_template '03 servidorweb - instalar' '03_servidorweb' '03_servidorweb/tasks.yaml'
create_template '03 servidorweb - desinstalar' '03_servidorweb' '03_servidorweb/tasks_uninstall.yaml'
create_template '14 Docker - instalar' '14_docker' '14_docker/tasks/docker_install.yaml'
create_template '14 Docker - desplegar contenedor' '14_docker' '14_docker/tasks/docker_deploy.yaml'
create_template '14 Docker - retirar contenedor' '14_docker' '14_docker/tasks/docker_undeploy.yaml'
create_template '14 Docker Compose - desplegar' '14_docker' '14_docker/tasks/docker_compose_deploy.yaml'
create_template '14 Docker Compose - retirar' '14_docker' '14_docker/tasks/docker_compose_undeploy.yaml'
create_template '14 Docker - desinstalar' '14_docker' '14_docker/tasks/docker_uninstall.yaml'
