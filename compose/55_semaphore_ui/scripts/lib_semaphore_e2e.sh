#!/usr/bin/env bash
set -euo pipefail

E2E_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$E2E_DIR"

for required_file in .env secrets.env e2e.env; do
    if [[ ! -f "$required_file" ]]; then
        echo "Falta $required_file. Ejecuta ./00_init.sh y copia e2e.env.example a e2e.env." >&2
        return 1
    fi
done

if [[ ! -f e2e-secrets.env ]]; then
    umask 077
    printf 'E2E_USER_PASSWORD=%s\n' "$(openssl rand -hex 24)" > e2e-secrets.env
    chmod 600 e2e-secrets.env
fi

set -a
# shellcheck disable=SC1091
source .env
# shellcheck disable=SC1091
source secrets.env
# shellcheck disable=SC1091
source e2e.env
# shellcheck disable=SC1091
source e2e-secrets.env
set +a

: "${E2E_TARGET_HOST:?Define E2E_TARGET_HOST en e2e.env}"
: "${E2E_TARGET_USER:?Define E2E_TARGET_USER en e2e.env}"
: "${E2E_SSH_PRIVATE_KEY:?Define E2E_SSH_PRIVATE_KEY en e2e.env}"
: "${E2E_USER_PASSWORD:?No está definido E2E_USER_PASSWORD en e2e-secrets.env}"

if [[ ! -r "$E2E_SSH_PRIVATE_KEY" ]]; then
    echo "No se puede leer la clave SSH: $E2E_SSH_PRIVATE_KEY" >&2
    return 1
fi

command -v curl >/dev/null || { echo 'Falta curl.' >&2; return 1; }
command -v jq >/dev/null || { echo 'Falta jq.' >&2; return 1; }

SEMAPHORE_URL="http://127.0.0.1:${SEMAPHORE_HTTP_PORT:-3001}"
E2E_STATE_DIR="$E2E_DIR/.e2e-state"
mkdir -p "$E2E_STATE_DIR"
chmod 700 "$E2E_STATE_DIR"
API_COOKIE="$(mktemp)"
API_RESPONSE="$(mktemp)"
trap 'rm -f "$API_COOKIE" "$API_RESPONSE"' EXIT

api_login() {
    local username="$1" password="$2" payload status
    payload="$(jq -nc --arg auth "$username" --arg password "$password" '{auth:$auth,password:$password}')"
    status="$(curl -sS -c "$API_COOKIE" -b "$API_COOKIE" -o "$API_RESPONSE" -w '%{http_code}' \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        --data-binary "$payload" "$SEMAPHORE_URL/api/auth/login")" || {
        echo 'No se pudo conectar con Semaphore.' >&2
        return 1
    }
    if [[ "$status" != 204 ]]; then
        echo "Login Semaphore rechazado (HTTP $status)." >&2
        return 1
    fi
}

api_request() {
    local method="$1" path="$2" payload="${3-}" status
    local -a args=(-sS -b "$API_COOKIE" -c "$API_COOKIE" -o "$API_RESPONSE" -w '%{http_code}' -X "$method" -H 'Accept: application/json')
    if [[ -n "$payload" ]]; then
        args+=(-H 'Content-Type: application/json' --data-binary "$payload")
    fi
    status="$(curl "${args[@]}" "$SEMAPHORE_URL$path")" || {
        echo "Error de red al llamar a Semaphore: $method $path" >&2
        return 1
    }
    case "$status" in
        2??) cat "$API_RESPONSE" ;;
        *)
            echo "Semaphore devolvió HTTP $status en $method $path:" >&2
            cat "$API_RESPONSE" >&2
            echo >&2
            return 1
            ;;
    esac
}

api_admin_login() {
    api_login "${SEMAPHORE_ADMIN_USER:-admin}" "$SEMAPHORE_ADMIN_PASSWORD"
}

state_read() {
    local key="$1" file="$E2E_STATE_DIR/$1"
    if [[ ! -s "$file" ]]; then
        echo "Falta el dato $key. Ejecuta primero los scripts de preparación desde el 10." >&2
        return 1
    fi
    cat "$file"
}

state_write_id() {
    local key="$1" response="$2" id
    id="$(jq -er '.id | tostring' <<<"$response")" || {
        echo "Semaphore no devolvió un id para $key." >&2
        return 1
    }
    printf '%s\n' "$id" > "$E2E_STATE_DIR/$key"
    printf '%s\n' "$id"
}

run_template() {
    local template_name="$1" project_id templates template_id task task_id status
    local attempt
    project_id="$(state_read project_id)"
    templates="$(api_request GET "/api/project/$project_id/templates?sort=name&order=asc")"
    template_id="$(jq -r --arg name "$template_name" '[.[] | select(.name == $name) | .id] | first // empty' <<<"$templates")"
    if [[ -z "$template_id" ]]; then
        echo "No existe la plantilla Semaphore '$template_name'. Ejecuta ./16_create_templates.sh." >&2
        return 1
    fi
    task="$(api_request POST "/api/project/$project_id/tasks" "$(jq -nc --argjson template_id "$template_id" --arg message "E2E: $template_name" '{template_id:$template_id,message:$message}')")"
    task_id="$(jq -er '.id | tostring' <<<"$task")"
    printf 'Tarea %s (id=%s): ' "$template_name" "$task_id"
    for ((attempt=1; attempt<=180; attempt++)); do
        task="$(api_request GET "/api/project/$project_id/tasks/$task_id")"
        status="$(jq -r '.status // "unknown"' <<<"$task")"
        case "$status" in
            success)
                echo success
                printf '%s\n' "$task_id" > "$E2E_STATE_DIR/last_task_id"
                return 0
                ;;
            error|stopped|failed)
                echo "$status"
                echo 'Salida de la tarea:' >&2
                api_request GET "/api/project/$project_id/tasks/$task_id/output" | jq -r '.[]? | .output // .task // tostring' >&2 || true
                return 1
                ;;
            waiting|running|queued)
                ;;
            *)
                echo "estado inesperado: $status" >&2
                ;;
        esac
        sleep 2
    done
    echo 'timeout (6 minutos)' >&2
    return 1
}

check_http_up() {
    local url="$1" attempt code
    for ((attempt=1; attempt<=30; attempt++)); do
        code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 4 "$url" 2>/dev/null || true)"
        if [[ "$code" =~ ^[23][0-9][0-9]$ ]]; then
            printf 'HTTP %s en %s\n' "$code" "$url"
            return 0
        fi
        sleep 2
    done
    echo "No respondió HTTP en $url." >&2
    return 1
}

check_http_down() {
    local url="$1" attempt code
    for ((attempt=1; attempt<=5; attempt++)); do
        code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 4 "$url" 2>/dev/null || true)"
        if [[ -z "$code" || "$code" == 000 ]]; then
            printf 'Sin servicio en %s\n' "$url"
            return 0
        fi
        sleep 2
    done
    echo "El servicio sigue respondiendo en $url (HTTP $code)." >&2
    return 1
}
remote_ssh() {
    ssh -i "$E2E_SSH_PRIVATE_KEY" -o BatchMode=yes -o ConnectTimeout=8 \
        -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes \
        "$E2E_TARGET_USER@$E2E_TARGET_HOST" "$@"
}

require_remote_package_absent() {
    local package="$1"
    if remote_ssh "dpkg-query -W -f='\${db:Status-Status}' '$package' 2>/dev/null | grep -qx installed"; then
        echo "Se conserva el paquete preexistente '$package'; no se ejecutará la retirada." >&2
        return 1
    fi
}
