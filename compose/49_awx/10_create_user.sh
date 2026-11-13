#!/usr/bin/env bash
# Crea (o reutiliza) la cuenta AWX dedicada que lanzará las plantillas.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

api_admin_login
user_id="$(find_by users username "$E2E_USER_LOGIN")"
payload="$(jq -n \
    --arg username "$E2E_USER_LOGIN" \
    --arg password "$E2E_USER_PASSWORD" \
    --arg name "$E2E_USER_NAME" \
    --arg email "$E2E_USER_EMAIL" \
    '{username:$username,password:$password,first_name:$name,last_name:"E2E",email:$email,is_superuser:false,is_system_auditor:false}')"

if [[ -n "$user_id" ]]; then
    # Se sincroniza la contraseña con e2e-secrets.env para poder reutilizar la cuenta.
    api_request PATCH "/api/v2/users/$user_id/" "$(jq -n --arg password "$E2E_USER_PASSWORD" '{password:$password}')" >/dev/null
    printf '%s\n' "$user_id" > "$E2E_STATE_DIR/user_id"
    echo "Usuario AWX $E2E_USER_LOGIN reutilizado (id=$user_id)."
else
    response="$(api_request POST /api/v2/users/ "$payload")"
    echo "Usuario AWX $E2E_USER_LOGIN creado (id=$(state_write_id user_id "$response"))."
fi
