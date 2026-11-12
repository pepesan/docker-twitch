#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [[ "${E2E_CONFIRM_DOCKER_PURGE:-}" != YES ]]; then
    echo 'Esta prueba elimina Docker y sus datos del destino (contenedores, imágenes y volúmenes).' >&2
    echo 'Primero confirma que la VM es desechable y que Docker no contiene datos ajenos al laboratorio.' >&2
    echo 'Vuelve a ejecutarla con: E2E_CONFIRM_DOCKER_PURGE=YES ./90_e2e.sh' >&2
    exit 1
fi

./80_deploy_semaphore_with_examples.sh
./24_undeploy_docker_compose.sh
./25_uninstall_docker.sh

# Clear lifecycle markers only after all deploy and teardown checks have passed.
rm -f \
    .e2e-state/webserver_installed \
    .e2e-state/webserver_uninstalled \
    .e2e-state/target_docker_was_clean \
    .e2e-state/docker_installed \
    .e2e-state/container_deployed \
    .e2e-state/container_undeployed \
    .e2e-state/compose_deployed \
    .e2e-state/compose_undeployed \
    .e2e-state/docker_uninstalled \
    .e2e-state/last_task_id

echo 'E2E completo: despliegues y retiradas verificados; el destino quedó limpio.'
echo 'Semaphore conserva el proyecto, sus plantillas y el historial de tareas.'
