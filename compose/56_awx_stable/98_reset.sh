#!/usr/bin/env bash
# Deja el laboratorio como recién instalado, para repetir una práctica desde cero:
#  - AWX: elimina todo lo creado (plantillas, proyectos, inventarios, credenciales no gestionadas,
#    equipos, usuarios salvo admin, organizaciones salvo Default, notificadores) y el historial de trabajos.
#    Se conservan los datos de demostración que trae AWX.
#  - Destino: desinstala nginx y Docker (y sus datos) si los dejó una práctica anterior.
# DESTRUCTIVO en el destino: solo para una máquina de laboratorio desechable (la de e2e.env).
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

echo '== AWX: eliminar recursos creados'
api_admin_login
DEMO='["Demo Project","Demo Inventory","Demo Credential","Ansible Galaxy","Demo Job Template"]'

borrar() { # endpoint campo_nombre
    local endpoint="$1" field="${2:-name}" ids id
    ids="$(api_request GET "/api/v2/$endpoint/?page_size=200" | jq -r --arg f "$field" --argjson demo "$DEMO" \
        '.results[] | select((.managed // false) | not) | select(.[$f] as $n | ($demo | index($n)) | not) | .id')"
    for id in $ids; do
        api_request DELETE "/api/v2/$endpoint/$id/" >/dev/null 2>&1 || echo "   (no se pudo borrar $endpoint/$id; se reintenta)" >&2
    done
}

for _ in 1 2 3; do
    borrar workflow_job_templates
    borrar job_templates
    borrar projects
    borrar inventories
    borrar credentials
    borrar teams
    borrar notification_templates
    borrar credential_types
    # usuarios: todos menos admin; organizaciones: todas menos Default
    for id in $(api_request GET '/api/v2/users/?page_size=200' | jq -r '.results[] | select(.username != "admin") | .id'); do
        api_request DELETE "/api/v2/users/$id/" >/dev/null 2>&1 || true
    done
    for id in $(api_request GET '/api/v2/organizations/?page_size=200' | jq -r '.results[] | select(.name != "Default") | .id'); do
        api_request DELETE "/api/v2/organizations/$id/" >/dev/null 2>&1 || true
    done
    sleep 3
done

# Los inventarios se borran en segundo plano en AWX: se espera a que desaparezcan.
for _ in $(seq 1 30); do
    pendientes="$(api_request GET '/api/v2/inventories/?page_size=200' | jq -r --argjson demo "$DEMO" '[.results[] | select(.name as $n | ($demo | index($n)) | not)] | length')"
    [[ "$pendientes" == 0 ]] && break
    sleep 2
done

echo '== AWX: borrar historial de trabajos'
( cd "$AWX_LAB_DIR" && docker compose exec -T awx awx-manage cleanup_jobs --days=0 >/dev/null 2>&1 ) || echo '   (cleanup_jobs no pudo ejecutarse)' >&2

echo '== Destino: dejarlo sin nginx ni Docker'
if [[ "$E2E_TARGET_USER" == root ]]; then shell_remoto='bash -s'; else shell_remoto='sudo -n bash -s'; fi
remote_ssh "$shell_remoto" <<'REMOTO'
set -u
export DEBIAN_FRONTEND=noninteractive
if command -v docker >/dev/null 2>&1; then
    docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true
fi
instalados=""
for p in nginx nginx-common nginx-core docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-compose-v2; do
    [ "$(dpkg-query -W -f='${db:Status-Status}' "$p" 2>/dev/null || true)" = installed ] && instalados="$instalados $p"
done
[ -z "$instalados" ] || apt-get purge -y -qq $instalados >/dev/null 2>&1
rm -rf /var/lib/docker /var/lib/containerd /etc/docker /etc/nginx /home/alumno/deploy /var/lib/ansible-docker-example \
    /etc/apt/sources.list.d/docker-13-example.sources /etc/apt/keyrings/docker-13-example.asc
for p in nginx nginx-common docker-ce; do
    [ "$(dpkg-query -W -f='${db:Status-Status}' "$p" 2>/dev/null || true)" = installed ] && { echo "SIGUE INSTALADO: $p" >&2; exit 1; }
done
echo 'destino limpio'
REMOTO
rm -rf "$E2E_STATE_DIR"/* 2>/dev/null || true

echo '== Comprobación'
for e in job_templates projects inventories credentials users organizations hosts jobs; do
    printf '%s: ' "$e"; api_request GET "/api/v2/$e/?page_size=50" | jq -r '[.count, ([.results[]|(.name // .username)]|join(", "))]|@tsv'
done
