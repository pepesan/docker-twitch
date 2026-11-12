#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
require_remote_package_absent nginx
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template '03 servidorweb - instalar'
check_http_up "http://$E2E_TARGET_HOST/"
printf 'webserver_installed\n' > "$E2E_STATE_DIR/webserver_installed"
