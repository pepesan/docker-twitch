#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
[[ -s "$E2E_STATE_DIR/container_deployed" ]] || { echo 'Ejecuta primero ./21_deploy_docker_container.sh.' >&2; exit 1; }
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template '14 Docker - retirar contenedor'
check_http_down "http://$E2E_TARGET_HOST:81/"
printf 'container_undeployed\n' > "$E2E_STATE_DIR/container_undeployed"
