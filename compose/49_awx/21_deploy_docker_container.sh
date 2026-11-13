#!/usr/bin/env bash
# Despliega un contenedor nginx con docker run (puerto 81) mediante AWX.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

[[ -s "$E2E_STATE_DIR/docker_installed" ]] || { echo 'Ejecuta primero ./20_install_docker.sh.' >&2; exit 1; }
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template 'desplegar-contenedor-laboratorio'
check_http_up "http://$E2E_TARGET_HOST:81/"
printf 'container_deployed\n' > "$E2E_STATE_DIR/container_deployed"
