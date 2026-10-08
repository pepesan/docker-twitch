#!/usr/bin/env bash
# AWX ya trae registrados globalmente los entornos de ejecución
# ("AWX EE (latest)" y "Control Plane Execution Environment", ambos
# quay.io/ansible/awx-ee:latest) nada más arrancar, pero NI la
# organización "Default" ni el "Demo Job Template" los tienen asignados
# explícitamente (default_environment / execution_environment = null en
# la API) — por eso en la UI no se ve ningún enganche, aunque los jobs
# funcionen por un fallback implícito a un EE global. Este script lo deja
# enlazado de verdad, y pre-descarga la imagen en cada execution node
# para que el primer job no tenga que tirar de red.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

API="https://localhost:${AWX_HTTPS_PORT}/api/v2"
AUTH=(-u "admin:${AWX_ADMIN_PASSWORD}")

EE_ID=$(curl -sk "${AUTH[@]}" "${API}/execution_environments/?name=AWX%20EE%20(latest)" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["results"][0]["id"])')
echo "Execution Environment 'AWX EE (latest)' id=${EE_ID}"

ORG_ID=$(curl -sk "${AUTH[@]}" "${API}/organizations/?name=Default" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["results"][0]["id"])')

curl -sk "${AUTH[@]}" -X PATCH "${API}/organizations/${ORG_ID}/" \
    -H "Content-Type: application/json" \
    -d "{\"default_environment\": ${EE_ID}}" >/dev/null
echo "Organización Default (id=${ORG_ID}): default_environment -> ${EE_ID}"

JT_ID=$(curl -sk "${AUTH[@]}" "${API}/job_templates/?name=Demo%20Job%20Template" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["results"][0]["id"])')

curl -sk "${AUTH[@]}" -X PATCH "${API}/job_templates/${JT_ID}/" \
    -H "Content-Type: application/json" \
    -d "{\"execution_environment\": ${EE_ID}}" >/dev/null
echo "Demo Job Template (id=${JT_ID}): execution_environment -> ${EE_ID}"

echo
echo "Pre-descargando la imagen en cada execution node (si no la tienen ya)..."
for svc in $(docker compose ps --services | grep '^receptor-[0-9]'); do
    echo "  ${svc}..."
    docker compose exec -T "$svc" podman pull quay.io/ansible/awx-ee:latest >/dev/null 2>&1 \
        && echo "    OK" || echo "    (ya la tenía o falló, revisa con: docker compose exec ${svc} podman images)"
done

echo
echo "Verificación:"
curl -sk "${AUTH[@]}" "${API}/organizations/${ORG_ID}/" | python3 -c 'import json,sys; print("  org.default_environment =", json.load(sys.stdin)["default_environment"])'
curl -sk "${AUTH[@]}" "${API}/job_templates/${JT_ID}/" | python3 -c 'import json,sys; print("  job_template.execution_environment =", json.load(sys.stdin)["execution_environment"])'
