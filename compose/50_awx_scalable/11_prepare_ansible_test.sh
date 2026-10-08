#!/usr/bin/env bash
# Prepara la prueba de Ansible real: asegura que los datos demo están
# cargados (organización/proyecto/inventario/"Demo Job Template" sobre
# ansible-tower-samples) y localiza su id vía la API, guardándolo en
# /tmp/awx_demo_job_template_id para que 12_run_ansible_test.sh lo
# recoja sin que haya que copiarlo a mano. Idempotente: create_preload_data
# no duplica datos si ya existen, y esto solo lee/escribe un fichero
# temporal con el id (siempre el mismo si los datos demo no cambian).
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

./03_preload_demo_data.sh

JT_ID=$(curl -sk -u "admin:${AWX_ADMIN_PASSWORD}" \
    "https://localhost:${AWX_HTTPS_PORT}/api/v2/job_templates/?name=Demo%20Job%20Template" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["results"][0]["id"])')

echo "$JT_ID" > /tmp/awx_demo_job_template_id
echo "Demo Job Template id=${JT_ID} (guardado en /tmp/awx_demo_job_template_id)"
echo "Lánzalo con: ./12_run_ansible_test.sh"
