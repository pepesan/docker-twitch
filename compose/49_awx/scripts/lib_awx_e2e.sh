#!/usr/bin/env bash
# Biblioteca común de los scripts E2E de este laboratorio
# (equivalente a scripts/lib_semaphore_e2e.sh del ejemplo 55).
#
# Se carga desde cada script con:
#   source "$(dirname "$0")/scripts/lib_awx_e2e.sh"
#
# Lee .env y secrets.env del laboratorio para conocer el puerto y la
# contraseña de admin.
set -euo pipefail

E2E_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

AWX_LAB_DIR="$E2E_DIR"
cd "$E2E_DIR"

for required_file in "$AWX_LAB_DIR/.env" "$AWX_LAB_DIR/secrets.env" e2e.env; do
    if [[ ! -f "$required_file" ]]; then
        echo "Falta $required_file." >&2
        echo "  e2e.env: copia e2e.env.example a e2e.env y revisa host, usuario y clave." >&2
        echo "  .env y secrets.env: ejecuta ./00_init.sh en $AWX_LAB_DIR." >&2
        return 1
    fi
done

if [[ ! -f e2e-secrets.env ]]; then
    ( umask 077; printf 'E2E_USER_PASSWORD=%s\n' "$(openssl rand -hex 12)" > e2e-secrets.env )
    echo 'Creado e2e-secrets.env con la contraseña del usuario E2E de AWX.' >&2
fi

set -a
# shellcheck disable=SC1091
source "$AWX_LAB_DIR/.env"
# shellcheck disable=SC1091
source "$AWX_LAB_DIR/secrets.env"
# shellcheck disable=SC1091
source e2e.env
# shellcheck disable=SC1091
source e2e-secrets.env
set +a

: "${E2E_TARGET_HOST:?Define E2E_TARGET_HOST en e2e.env}"
: "${E2E_TARGET_USER:?Define E2E_TARGET_USER en e2e.env}"
: "${E2E_SSH_PRIVATE_KEY:?Define E2E_SSH_PRIVATE_KEY en e2e.env}"
: "${E2E_USER_PASSWORD:?No está definido E2E_USER_PASSWORD en e2e-secrets.env}"
: "${AWX_ADMIN_PASSWORD:?No está definido AWX_ADMIN_PASSWORD en secrets.env del laboratorio}"

# Valores por defecto de los nombres de recursos del laboratorio.
E2E_TARGET_NAME="${E2E_TARGET_NAME:-lxd-vm-auto}"
E2E_BECOME="${E2E_BECOME:-true}"
E2E_REPOSITORY_URL="${E2E_REPOSITORY_URL:-https://github.com/pepesan/ejemplos-ansible.git}"
E2E_REPOSITORY_BRANCH="${E2E_REPOSITORY_BRANCH:-master}"
E2E_ORGANIZATION="${E2E_ORGANIZATION:-Default}"
E2E_INVENTORY_NAME="${E2E_INVENTORY_NAME:-laboratorio}"
E2E_PROJECT_NAME="${E2E_PROJECT_NAME:-ejemplo-webserver}"
E2E_CREDENTIAL_NAME="${E2E_CREDENTIAL_NAME:-${E2E_TARGET_USER}-${E2E_TARGET_NAME}}"
E2E_USER_LOGIN="${E2E_USER_LOGIN:-ansible_e2e}"
E2E_USER_NAME="${E2E_USER_NAME:-Usuario E2E Ansible}"
E2E_USER_EMAIL="${E2E_USER_EMAIL:-ansible-e2e@localhost}"
E2E_JOB_TIMEOUT="${E2E_JOB_TIMEOUT:-900}"

if [[ ! -r "$E2E_SSH_PRIVATE_KEY" ]]; then
    echo "No se puede leer la clave privada indicada en E2E_SSH_PRIVATE_KEY." >&2
    return 1
fi

for tool in curl jq ssh openssl; do
    command -v "$tool" >/dev/null || { echo "Falta la herramienta $tool." >&2; return 1; }
done

AWX_URL="https://127.0.0.1:${AWX_HTTPS_PORT:-8043}"
E2E_STATE_DIR="$E2E_DIR/.e2e-state"
mkdir -p "$E2E_STATE_DIR"
chmod 700 "$E2E_STATE_DIR"
API_AUTH="$(mktemp)"
API_RESPONSE="$(mktemp)"
trap 'rm -f "$API_AUTH" "$API_RESPONSE"' EXIT

# --- API de AWX -------------------------------------------------------------

# api_login <usuario> <contraseña>
# AWX acepta autenticación básica en /api/v2/. Las credenciales se pasan a
# curl con un fichero de configuración 0600 para que no aparezcan en `ps`.
api_login() {
    local username="$1" password="$2" escaped status
    escaped="${password//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    ( umask 077; printf 'user = "%s:%s"\n' "$username" "$escaped" > "$API_AUTH" )
    status="$(curl -sS -k -K "$API_AUTH" -o "$API_RESPONSE" -w '%{http_code}' \
        -H 'Accept: application/json' "$AWX_URL/api/v2/me/")" || {
        echo 'No se pudo conectar con AWX.' >&2
        return 1
    }
    if [[ "$status" != 200 ]]; then
        echo "Login AWX rechazado para '$username' (HTTP $status)." >&2
        return 1
    fi
}

api_admin_login() {
    api_login admin "$AWX_ADMIN_PASSWORD"
}

# api_request <MÉTODO> <ruta> [json]
# El cuerpo viaja por stdin para que las claves privadas no queden en `ps`.
api_request() {
    local method="$1" path="$2" payload="${3-}" status
    [[ -s "$API_AUTH" ]] || { echo 'Falta autenticación: llama antes a api_login.' >&2; return 1; }
    local -a args=(-sS -k -K "$API_AUTH" -o "$API_RESPONSE" -w '%{http_code}' -X "$method" -H "Accept: ${API_ACCEPT:-application/json}")
    if [[ -n "$payload" ]]; then
        args+=(-H 'Content-Type: application/json' --data-binary @-)
        status="$(printf '%s' "$payload" | curl "${args[@]}" "$AWX_URL$path")" || {
            echo "Error de red al llamar a AWX: $method $path" >&2
            return 1
        }
    else
        status="$(curl "${args[@]}" "$AWX_URL$path")" || {
            echo "Error de red al llamar a AWX: $method $path" >&2
            return 1
        }
    fi
    case "$status" in
        2??) cat "$API_RESPONSE" ;;
        *)
            echo "AWX devolvió HTTP $status en $method $path:" >&2
            cat "$API_RESPONSE" >&2
            echo >&2
            return 1
            ;;
    esac
}

# find_by <endpoint> <campo> <valor> [consulta_extra] -> id, o vacío si no existe.
find_by() {
    local endpoint="$1" field="$2" value="$3" extra="${4-}" encoded
    encoded="$(jq -rn --arg v "$value" '$v|@uri')"
    api_request GET "/api/v2/$endpoint/?$field=$encoded&page_size=5${extra:+&$extra}" | jq -r '.results[0].id // empty'
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
        echo "AWX no devolvió un id para $key." >&2
        return 1
    }
    printf '%s\n' "$id" > "$E2E_STATE_DIR/$key"
    printf '%s\n' "$id"
}

# wait_job <endpoint> <id> <etiqueta>
# endpoint: jobs | project_updates | ad_hoc_commands
wait_job() {
    local endpoint="$1" job_id="$2" label="$3" attempt max status job
    max=$(( E2E_JOB_TIMEOUT / 2 ))
    printf '%s (id=%s): ' "$label" "$job_id"
    for ((attempt=1; attempt<=max; attempt++)); do
        job="$(api_request GET "/api/v2/$endpoint/$job_id/")"
        status="$(jq -r '.status // "unknown"' <<<"$job")"
        case "$status" in
            successful)
                echo successful
                return 0
                ;;
            failed|error|canceled)
                echo "$status"
                echo 'Salida del trabajo:' >&2
                API_ACCEPT=text/plain api_request GET "/api/v2/$endpoint/$job_id/stdout/?format=txt" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' >&2 || true
                return 1
                ;;
            new|pending|waiting|running)
                ;;
            *)
                echo "estado inesperado: $status" >&2
                ;;
        esac
        sleep 2
    done
    echo "timeout ($E2E_JOB_TIMEOUT s)" >&2
    return 1
}

# wait_project_sync <id>: espera a que AWX termine de sincronizar el proyecto.
wait_project_sync() {
    local project_id="$1" attempt status project
    printf 'Sincronización del proyecto (id=%s): ' "$project_id"
    for ((attempt=1; attempt<=150; attempt++)); do
        project="$(api_request GET "/api/v2/projects/$project_id/")"
        status="$(jq -r '.status' <<<"$project")"
        case "$status" in
            successful) echo successful; return 0 ;;
            failed|error|canceled)
                echo "$status"
                API_ACCEPT=text/plain api_request GET "/api/v2/project_updates/$(jq -r '.summary_fields.last_job.id' <<<"$project")/stdout/?format=txt" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' >&2 || true
                return 1
                ;;
        esac
        sleep 2
    done
    echo 'timeout (300 s)' >&2
    return 1
}

# run_template <nombre de la plantilla>: lanza la plantilla y espera al resultado.
run_template() {
    local template_name="$1" template_id launch job_id
    template_id="$(find_by job_templates name "$template_name")"
    if [[ -z "$template_id" ]]; then
        echo "No existe la plantilla AWX '$template_name'. Ejecuta ./16_create_templates.sh." >&2
        return 1
    fi
    launch="$(api_request POST "/api/v2/job_templates/$template_id/launch/" '{}')"
    job_id="$(jq -er '.job | tostring' <<<"$launch")"
    wait_job jobs "$job_id" "Trabajo $template_name" || return 1
    printf '%s\n' "$job_id" > "$E2E_STATE_DIR/last_job_id"
}

# --- Comprobaciones en el destino ------------------------------------------

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

# remote_root <comando>: ejecuta con privilegios (sudo sin contraseña salvo que el usuario sea root).
remote_root() {
    if [[ "$E2E_TARGET_USER" == root ]]; then
        remote_ssh "$@"
    else
        remote_ssh "sudo -n sh -c '$*'"
    fi
}

require_remote_package_absent() {
    local package="$1"
    if remote_ssh "dpkg-query -W -f='\${db:Status-Status}' '$package' 2>/dev/null | grep -qx installed"; then
        echo "Se conserva el paquete preexistente '$package'; no se ejecutará la instalación." >&2
        return 1
    fi
}
