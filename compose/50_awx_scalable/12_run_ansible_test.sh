#!/usr/bin/env bash
# Lanza el "Demo Job Template" vía API (requiere haber ejecutado antes
# ./11_prepare_ansible_test.sh). Guarda el job id en
# /tmp/awx_last_test_job_id para que 13_check_ansible_test.sh lo recoja.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

if [ ! -f /tmp/awx_demo_job_template_id ]; then
    echo "No existe /tmp/awx_demo_job_template_id — ejecuta antes ./11_prepare_ansible_test.sh" >&2
    exit 1
fi
JT_ID=$(cat /tmp/awx_demo_job_template_id)

JOB_ID=$(curl -sk -u "admin:${AWX_ADMIN_PASSWORD}" -X POST \
    "https://localhost:${AWX_HTTPS_PORT}/api/v2/job_templates/${JT_ID}/launch/" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["job"])')

echo "$JOB_ID" > /tmp/awx_last_test_job_id
echo "Job lanzado: id=${JOB_ID}"
echo "Comprueba el resultado con: ./13_check_ansible_test.sh"
