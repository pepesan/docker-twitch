#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
api_admin_login
project_id="$(state_read project_id)"
user_id="$(state_read user_id)"

members="$(api_request GET "/api/project/$project_id/users?sort=username&order=asc")"
if jq -e --argjson id "$user_id" 'any(.[]; .id == $id)' <<<"$members" >/dev/null; then
    echo "Usuario $E2E_USER_LOGIN ya pertenece al proyecto $E2E_PROJECT_NAME."
else
    payload="$(jq -nc --argjson user_id "$user_id" '{user_id:$user_id,roles:["manager"]}')"
    api_request POST "/api/project/$project_id/users" "$payload" >/dev/null
    echo "Usuario $E2E_USER_LOGIN añadido como manager al proyecto."
fi
