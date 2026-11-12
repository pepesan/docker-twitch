#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
[[ -s "$E2E_STATE_DIR/webserver_installed" ]] || { echo 'Ejecuta primero ./18_install_webserver.sh.' >&2; exit 1; }
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template '03 servidorweb - desinstalar'
if remote_ssh 'dpkg-query -W -f="\${db:Status-Status}" nginx 2>/dev/null | grep -qx installed'; then
    echo 'Nginx continúa instalado después de la retirada.' >&2
    exit 1
fi
check_http_down "http://$E2E_TARGET_HOST/"
printf 'webserver_uninstalled\n' > "$E2E_STATE_DIR/webserver_uninstalled"
