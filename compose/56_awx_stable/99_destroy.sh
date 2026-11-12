#!/usr/bin/env bash
# Elimina de AWX los recursos que crean estos scripts (plantillas, proyecto,
# inventario, credencial y usuario E2E). No toca la organización, no destruye
# el laboratorio (para eso está 97_destroy_lab.sh) ni modifica el destino.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

echo "Se eliminarán de AWX: 8 plantillas, el proyecto $E2E_PROJECT_NAME, el inventario $E2E_INVENTORY_NAME,"
echo "la credencial $E2E_CREDENTIAL_NAME y el usuario $E2E_USER_LOGIN."
read -r -p 'Escribe DESTROY para confirmar: ' confirmation
if [[ "$confirmation" != DESTROY ]]; then
    echo 'Cancelado; no se ha borrado nada.'
    exit 0
fi

api_admin_login
delete_by() {
    local endpoint="$1" field="$2" value="$3" label="$4" id
    id="$(find_by "$endpoint" "$field" "$value")"
    if [[ -z "$id" ]]; then
        echo "$label: no existe."
        return 0
    fi
    api_request DELETE "/api/v2/$endpoint/$id/" >/dev/null
    echo "$label: eliminado."
}

for template_name in instalar-nginx-laboratorio desinstalar-nginx-laboratorio instalar-docker-laboratorio \
    desplegar-contenedor-laboratorio retirar-contenedor-laboratorio desplegar-compose-laboratorio \
    retirar-compose-laboratorio desinstalar-docker-laboratorio; do
    delete_by job_templates name "$template_name" "Plantilla $template_name"
done
delete_by projects name "$E2E_PROJECT_NAME" "Proyecto $E2E_PROJECT_NAME"
delete_by inventories name "$E2E_INVENTORY_NAME" "Inventario $E2E_INVENTORY_NAME"
delete_by credentials name "$E2E_CREDENTIAL_NAME" "Credencial $E2E_CREDENTIAL_NAME"
delete_by users username "$E2E_USER_LOGIN" "Usuario $E2E_USER_LOGIN"
rm -rf "$E2E_STATE_DIR"
echo 'Recursos AWX eliminados. e2e.env y e2e-secrets.env se conservan.'
