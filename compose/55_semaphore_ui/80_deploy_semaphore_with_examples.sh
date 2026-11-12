#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

./00_init.sh
if [[ ! -f e2e.env ]]; then
    cp e2e.env.example e2e.env
    chmod 600 e2e.env
    echo 'Creado e2e.env con los valores predeterminados del laboratorio; revísalo antes de continuar.' >&2
    exit 1
fi
set -a
# shellcheck disable=SC1091
source .env
set +a

./01_launch_compose.sh
for attempt in {1..60}; do
    if curl -fsS "http://127.0.0.1:${SEMAPHORE_HTTP_PORT:-3001}/api/ping" >/dev/null 2>&1; then
        break
    fi
    if (( attempt == 60 )); then
        echo 'Semaphore no respondió en 120 segundos.' >&2
        exit 1
    fi
    sleep 2
done

for script in \
    10_create_user.sh \
    11_create_project.sh \
    12_add_user_to_project.sh \
    13_create_ssh_key.sh \
    14_create_repository.sh \
    15_create_inventory.sh \
    16_create_templates.sh \
    17_check_e2e_resources.sh; do
    "./$script"
done

run_step() {
    local marker="$1" script="$2"
    if [[ -s ".e2e-state/$marker" ]]; then
        printf 'Paso ya completado; se conserva: %s\n' "$marker"
    else
        "./$script"
    fi
}

run_step webserver_installed 18_install_webserver.sh
run_step webserver_uninstalled 19_uninstall_webserver.sh
run_step docker_installed 20_install_docker.sh
run_step container_deployed 21_deploy_docker_container.sh
# Both examples publish host port 81. Remove the standalone container before Compose.
run_step container_undeployed 22_undeploy_docker_container.sh
run_step compose_deployed 23_deploy_docker_compose.sh

printf '\nDespliegue Semaphore listo.\n'
printf 'UI: http://localhost:%s/\n' "${SEMAPHORE_HTTP_PORT:-3001}"
printf 'Proyecto: Ansible LXC E2E\n'
printf 'WordPress (Compose): http://%s:81/\n' "$(. ./e2e.env; printf '%s' "$E2E_TARGET_HOST")"
printf 'Los resultados de las tareas y las plantillas están en Semaphore.\n'
printf 'Para ejecutar la prueba completa con retirada de recursos: E2E_CONFIRM_DOCKER_PURGE=YES ./90_e2e.sh\n'
