#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
[[ -s "$E2E_STATE_DIR/container_undeployed" ]] || { echo 'Ejecuta primero ./22_undeploy_docker_container.sh.' >&2; exit 1; }
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template '14 Docker Compose - desplegar'
check_http_up "http://$E2E_TARGET_HOST:81/"
printf 'compose_deployed\n' > "$E2E_STATE_DIR/compose_deployed"
