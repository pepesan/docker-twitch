#!/usr/bin/env bash
# Crea (o actualiza) las plantillas de trabajo, les enlaza la credencial Machine
# y concede a la cuenta E2E el rol Execute sobre cada una.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
inventory_id="$(state_read inventory_id)"
project_id="$(state_read project_id)"
credential_id="$(state_read credential_id)"
user_id="$(state_read user_id)"

ensure_template() {
    local name="$1" playbook="$2" description="$3" template_id payload response role_id
    payload="$(jq -n \
        --arg name "$name" --arg description "$description" --arg playbook "$playbook" \
        --argjson inventory "$inventory_id" --argjson project "$project_id" --arg become "$E2E_BECOME" \
        '{name:$name,description:$description,job_type:"run",inventory:$inventory,project:$project,playbook:$playbook,
          become_enabled:($become == "true"),verbosity:0}')"
    template_id="$(find_by job_templates name "$name")"
    if [[ -n "$template_id" ]]; then
        api_request PATCH "/api/v2/job_templates/$template_id/" "$payload" >/dev/null
        echo "Plantilla $name actualizada (id=$template_id)."
    else
        response="$(api_request POST /api/v2/job_templates/ "$payload")"
        template_id="$(jq -er '.id | tostring' <<<"$response")"
        echo "Plantilla $name creada (id=$template_id)."
    fi
    # Credencial Machine: AWX solo admite una, así que se asocia solo si aún no está.
    if ! api_request GET "/api/v2/job_templates/$template_id/credentials/" | jq -e --argjson c "$credential_id" '[.results[].id] | index($c) != null' >/dev/null; then
        api_request POST "/api/v2/job_templates/$template_id/credentials/" "$(jq -n --argjson id "$credential_id" '{id:$id}')" >/dev/null
    fi
    # Rol Execute para la cuenta E2E.
    role_id="$(api_request GET "/api/v2/job_templates/$template_id/object_roles/" | jq -er '.results[] | select(.name == "Execute") | .id')"
    api_request POST "/api/v2/users/$user_id/roles/" "$(jq -n --argjson id "$role_id" '{id:$id}')" >/dev/null
}

ensure_template 'instalar-nginx-laboratorio'          '03_servidorweb/tasks.yaml'                       'Instala el servidor web (grupo ubuntu)'
ensure_template 'desinstalar-nginx-laboratorio'       '03_servidorweb/tasks_uninstall.yaml'             'Desinstala el servidor web (grupo ubuntu)'
ensure_template 'instalar-docker-laboratorio'         '14_docker/awx/docker_install.yaml'             'Instala Docker (grupo docker)'
ensure_template 'desplegar-contenedor-laboratorio'    '14_docker/awx/docker_deploy.yaml'              'Despliega un contenedor nginx con volumen en el puerto 81'
ensure_template 'retirar-contenedor-laboratorio'      '14_docker/awx/docker_undeploy.yaml'            'Retira el contenedor nginx y su volumen'
ensure_template 'desplegar-compose-laboratorio'       '14_docker/awx/docker_compose_deploy.yaml'      'Despliega WordPress y MySQL con Docker Compose en el puerto 81'
ensure_template 'retirar-compose-laboratorio'         '14_docker/awx/docker_compose_undeploy.yaml'    'Retira el despliegue de Docker Compose'
ensure_template 'desinstalar-docker-laboratorio'      '14_docker/awx/docker_uninstall.yaml'           'Desinstala Docker y borra /var/lib/docker (solo VM desechable)'
