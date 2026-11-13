#!/usr/bin/env bash
# Comprueba, sin modificar el destino, que los recursos AWX están completos y
# que AWX llega por SSH a la máquina (comando ad hoc con el módulo ping).
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

fail() { echo "FALLO: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

api_admin_login
organization_id="$(state_read organization_id)"
user_id="$(state_read user_id)"
credential_id="$(state_read credential_id)"
project_id="$(state_read project_id)"
inventory_id="$(state_read inventory_id)"

# Usuario y organización
api_request GET "/api/v2/organizations/$organization_id/users/?username=$E2E_USER_LOGIN" | jq -e '.count == 1' >/dev/null \
    || fail "El usuario $E2E_USER_LOGIN no pertenece a la organización $E2E_ORGANIZATION"
ok "usuario $E2E_USER_LOGIN en la organización $E2E_ORGANIZATION"

# Credencial: tipo Machine, usuario correcto y clave cifrada (nunca en claro)
credential="$(api_request GET "/api/v2/credentials/$credential_id/")"
jq -e --arg user "$E2E_TARGET_USER" '.summary_fields.credential_type.name == "Machine" and .inputs.username == $user' <<<"$credential" >/dev/null \
    || fail "La credencial no es Machine o su usuario no es $E2E_TARGET_USER"
jq -e '.inputs.ssh_key_data == "$encrypted$"' <<<"$credential" >/dev/null \
    || fail 'La clave SSH no figura como $encrypted$ en la API'
ok "credencial Machine de $E2E_TARGET_USER con clave cifrada"

# Proyecto sincronizado
project="$(api_request GET "/api/v2/projects/$project_id/")"
jq -e --arg url "$E2E_REPOSITORY_URL" --arg branch "$E2E_REPOSITORY_BRANCH" \
    '.status == "successful" and .scm_url == $url and .scm_branch == $branch' <<<"$project" >/dev/null \
    || fail "El proyecto no está sincronizado con $E2E_REPOSITORY_URL ($E2E_REPOSITORY_BRANCH)"
ok "proyecto $E2E_PROJECT_NAME sincronizado"

# Inventario: host con ansible_host y grupos ubuntu y docker
host_vars="$(api_request GET "/api/v2/inventories/$inventory_id/hosts/?name=$E2E_TARGET_NAME" | jq -er '.results[0].variables')"
grep -qx "ansible_host: $E2E_TARGET_HOST" <<<"$host_vars" || fail "ansible_host de $E2E_TARGET_NAME no coincide con $E2E_TARGET_HOST"
for group_name in ubuntu docker; do
    api_request GET "/api/v2/inventories/$inventory_id/groups/?name=$group_name" | jq -e '.count == 1' >/dev/null || fail "Falta el grupo $group_name"
    group_id="$(find_by groups name "$group_name" "inventory=$inventory_id")"
    api_request GET "/api/v2/groups/$group_id/hosts/?name=$E2E_TARGET_NAME" | jq -e '.count == 1' >/dev/null || fail "$E2E_TARGET_NAME no está en el grupo $group_name"
done
ok "inventario $E2E_INVENTORY_NAME: $E2E_TARGET_NAME ($E2E_TARGET_HOST) en ubuntu y docker"

# Plantillas: 8, con credencial Machine, become coherente y Execute para la cuenta E2E
user_roles="$(api_request GET "/api/v2/users/$user_id/roles/?page_size=200")"
count=0
for template_name in instalar-nginx-laboratorio desinstalar-nginx-laboratorio instalar-docker-laboratorio \
    desplegar-contenedor-laboratorio retirar-contenedor-laboratorio desplegar-compose-laboratorio \
    retirar-compose-laboratorio desinstalar-docker-laboratorio; do
    template_id="$(find_by job_templates name "$template_name")"
    [[ -n "$template_id" ]] || fail "Falta la plantilla $template_name"
    template="$(api_request GET "/api/v2/job_templates/$template_id/")"
    jq -e --argjson inv "$inventory_id" --argjson proj "$project_id" --arg become "$E2E_BECOME" \
        '.inventory == $inv and .project == $proj and .job_type == "run" and .become_enabled == ($become == "true")' <<<"$template" >/dev/null \
        || fail "La plantilla $template_name no enlaza inventario/proyecto/become esperados"
    api_request GET "/api/v2/job_templates/$template_id/credentials/" | jq -e --argjson c "$credential_id" '[.results[].id] | index($c) != null' >/dev/null \
        || fail "La plantilla $template_name no tiene la credencial Machine"
    jq -e --argjson t "$template_id" 'any(.results[]; .name == "Execute" and .summary_fields.resource_id == $t)' <<<"$user_roles" >/dev/null \
        || fail "$E2E_USER_LOGIN no tiene el rol Execute en $template_name"
    count=$((count + 1))
done
ok "$count plantillas completas y ejecutables por $E2E_USER_LOGIN"

# Conectividad real AWX -> destino (no cambia nada en la máquina)
payload="$(jq -n --argjson inv "$inventory_id" --argjson cred "$credential_id" \
    '{job_type:"run",inventory:$inv,credential:$cred,module_name:"ping",limit:"ubuntu",verbosity:0,become_enabled:false}')"
adhoc="$(api_request POST /api/v2/ad_hoc_commands/ "$payload")"
wait_job ad_hoc_commands "$(jq -er '.id | tostring' <<<"$adhoc")" 'Ping ad hoc desde AWX' || fail 'AWX no consigue conectar por SSH con el destino'
ok "AWX alcanza $E2E_TARGET_NAME por SSH"
