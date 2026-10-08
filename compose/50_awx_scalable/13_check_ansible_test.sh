#!/usr/bin/env bash
# Uso: ./13_check_ansible_test.sh [job_id]
# Hace polling del job hasta que llega a un estado final, imprime en qué
# execution node corrió (para demostrar el reparto entre receptor-N) y
# sale con exit 0 solo si status=successful.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

JOB_ID="${1:-}"
if [ -z "$JOB_ID" ]; then
    if [ ! -f /tmp/awx_last_test_job_id ]; then
        echo "No hay job id: pásalo como argumento o ejecuta antes ./12_run_ansible_test.sh" >&2
        exit 1
    fi
    JOB_ID=$(cat /tmp/awx_last_test_job_id)
fi

URL="https://localhost:${AWX_HTTPS_PORT}/api/v2/jobs/${JOB_ID}/"

while true; do
    RESP=$(curl -sk -u "admin:${AWX_ADMIN_PASSWORD}" "$URL")
    STATUS=$(echo "$RESP" | python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])')
    case "$STATUS" in
        successful|failed|error|canceled)
            break
            ;;
        *)
            echo "job ${JOB_ID}: ${STATUS}..."
            sleep 3
            ;;
    esac
done

NODE=$(echo "$RESP" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("execution_node") or "")')
echo "job ${JOB_ID}: estado final = ${STATUS}"
echo "execution_node = ${NODE:-<vacío>}"

if [ "$STATUS" != "successful" ]; then
    echo "$RESP" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("job_explanation:", d.get("job_explanation")); print("result_traceback:", d.get("result_traceback"))'
    exit 1
fi
