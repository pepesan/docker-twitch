#!/usr/bin/env bash
# Ciclo completo sobre la LXC: servidor web, Docker, contenedor, Compose y
# purga final de Docker. Es destructivo en el destino (ver 25): exige
# E2E_CONFIRM_DOCKER_PURGE=YES y un destino sin nginx ni Docker previos.
set -euo pipefail
cd "$(dirname "$0")"

[[ "${E2E_CONFIRM_DOCKER_PURGE:-}" == YES ]] || {
    echo 'El E2E instala y después purga Docker (borra /var/lib/docker) en el destino.' >&2
    echo 'Confirma con: E2E_CONFIRM_DOCKER_PURGE=YES ./90_e2e.sh' >&2
    exit 1
}

./80_deploy_awx_with_examples.sh
rm -rf .e2e-state/webserver_* .e2e-state/target_docker_was_clean .e2e-state/docker_* \
    .e2e-state/container_* .e2e-state/compose_* .e2e-state/last_job_id
./18_install_webserver.sh
./19_uninstall_webserver.sh
./20_install_docker.sh
./21_deploy_docker_container.sh
./22_undeploy_docker_container.sh
./23_deploy_docker_compose.sh
./24_undeploy_docker_compose.sh
./25_uninstall_docker.sh
echo 'E2E completo: AWX instaló, desplegó, retiró y desinstaló en la LXC.'
rm -f .e2e-state/webserver_* .e2e-state/target_docker_was_clean .e2e-state/docker_* \
    .e2e-state/container_* .e2e-state/compose_* .e2e-state/last_job_id
