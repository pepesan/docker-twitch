#!/usr/bin/env bash
# Instala el servidor web con la plantilla instalar-nginx-laboratorio.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

if [[ -s "$E2E_STATE_DIR/webserver_installed" ]]; then
    echo 'El servidor web ya se instaló en esta ejecución; usa ./19_uninstall_webserver.sh para retirarlo.'
    exit 0
fi
require_remote_package_absent nginx
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template 'instalar-nginx-laboratorio'
check_http_up "http://$E2E_TARGET_HOST/"
printf 'webserver_installed\n' > "$E2E_STATE_DIR/webserver_installed"
