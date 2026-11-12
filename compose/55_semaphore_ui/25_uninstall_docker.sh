#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/scripts/lib_semaphore_e2e.sh"
[[ -s "$E2E_STATE_DIR/target_docker_was_clean" ]] || { echo 'Falta la comprobación de que Docker no tenía datos previos; no se desinstala.' >&2; exit 1; }
[[ -s "$E2E_STATE_DIR/container_undeployed" && -s "$E2E_STATE_DIR/compose_undeployed" ]] || { echo 'Retira primero el contenedor y Docker Compose (scripts 22 y 24).' >&2; exit 1; }
if [[ "${E2E_CONFIRM_DOCKER_PURGE:-}" != YES ]]; then
    echo 'docker_uninstall.yaml borra /var/lib/docker, /var/lib/containerd y /etc/docker.' >&2
    echo 'Tras verificar que solo contiene datos creados por este E2E, repite con E2E_CONFIRM_DOCKER_PURGE=YES.' >&2
    exit 1
fi
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template '14 Docker - desinstalar'
remote_ssh 'if command -v docker >/dev/null 2>&1; then echo docker-still-installed >&2; exit 1; fi; for d in /var/lib/docker /var/lib/containerd /etc/docker; do [ ! -e "$d" ] || { echo "Docker data remains: $d" >&2; exit 1; }; done'
printf 'docker_uninstalled\n' > "$E2E_STATE_DIR/docker_uninstalled"
echo 'Docker desinstalado; se han borrado sus datos locales en el destino.'
