#!/usr/bin/env bash
# Asocia la cuenta E2E a la organización. Es idempotente: repetir la
# asociación no duplica nada. El permiso para lanzar cada plantilla se
# concede en 16_create_templates.sh (rol Execute por plantilla).
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
organization_id="$(state_read organization_id)"
user_id="$(state_read user_id)"
api_request POST "/api/v2/organizations/$organization_id/users/" "$(jq -n --argjson id "$user_id" '{id:$id}')" >/dev/null
echo "Usuario $E2E_USER_LOGIN asociado a la organización $E2E_ORGANIZATION."
