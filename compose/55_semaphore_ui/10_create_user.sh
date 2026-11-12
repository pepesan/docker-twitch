#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login

users="$(api_request GET /api/users)"
user_id="$(jq -r --arg username "$E2E_USER_LOGIN" '[.[] | select(.username == $username) | .id] | .[0] // empty' <<<"$users")"
if [[ -n "$user_id" ]]; then
    existing_email="$(jq -r --argjson id "$user_id" '.[] | select(.id == $id) | .email' <<<"$users")"
    if [[ "$existing_email" != "$E2E_USER_EMAIL" ]]; then
        echo "El usuario '$E2E_USER_LOGIN' ya existe con otro email; no se modifica." >&2
        exit 1
    fi
    printf '%s\n' "$user_id" > "$E2E_STATE_DIR/user_id"
    echo "Usuario Semaphore existente reutilizado: $E2E_USER_LOGIN (id=$user_id)."
else
    payload="$(jq -nc --arg name "$E2E_USER_NAME" --arg username "$E2E_USER_LOGIN" --arg email "$E2E_USER_EMAIL" --arg password "$E2E_USER_PASSWORD" '{name:$name,username:$username,email:$email,password:$password,alert:false,admin:false,external:false}')"
    response="$(api_request POST /api/users "$payload")"
    user_id="$(state_write_id user_id "$response")"
    echo "Usuario Semaphore creado: $E2E_USER_LOGIN (id=$user_id)."
fi
echo 'La contraseña se guarda localmente en e2e-secrets.env (ignorado por Git).'
