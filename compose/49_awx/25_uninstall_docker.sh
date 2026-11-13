#!/usr/bin/env bash
# Desinstala Docker. DESTRUCTIVO: la plantilla borra /var/lib/docker,
# /var/lib/containerd y /etc/docker. Solo si Docker lo instaló este flujo (20)
# y exige confirmación explícita.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

[[ -s "$E2E_STATE_DIR/compose_undeployed" ]] || { echo 'Ejecuta primero ./24_undeploy_docker_compose.sh.' >&2; exit 1; }
[[ -s "$E2E_STATE_DIR/target_docker_was_clean" ]] || { echo 'Se niega a purgar Docker: no consta que el destino estuviera limpio antes de ./20_install_docker.sh.' >&2; exit 1; }
[[ "${E2E_CONFIRM_DOCKER_PURGE:-}" == YES ]] || {
    echo 'Esta plantilla borra /var/lib/docker, /var/lib/containerd y /etc/docker del destino.' >&2
    echo 'Confirma con: E2E_CONFIRM_DOCKER_PURGE=YES ./25_uninstall_docker.sh' >&2
    exit 1
}
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template 'desinstalar-docker-laboratorio'
remote_ssh '! command -v docker >/dev/null'
printf 'docker_uninstalled\n' > "$E2E_STATE_DIR/docker_uninstalled"
