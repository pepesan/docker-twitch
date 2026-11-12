#!/usr/bin/env bash
# Desinstala el servidor web con la plantilla desinstalar-nginx-laboratorio.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

[[ -s "$E2E_STATE_DIR/webserver_installed" ]] || { echo 'Ejecuta primero ./18_install_webserver.sh.' >&2; exit 1; }
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template 'desinstalar-nginx-laboratorio'
check_http_down "http://$E2E_TARGET_HOST/"
printf 'webserver_uninstalled\n' > "$E2E_STATE_DIR/webserver_uninstalled"
