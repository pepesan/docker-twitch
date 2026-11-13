#!/usr/bin/env bash
# Mismo ciclo que 90_e2e.sh, pero SIN limpieza final: levanta AWX con los
# recursos de ejemplo (80), instala y retira el servidor web (18, 19), instala
# Docker (20), despliega y retira el contenedor (21, 22) y deja desplegado el
# stack de Docker Compose (23).
#
# Al terminar quedan en el destino Docker, los contenedores de Compose y sus
# volúmenes, y en AWX los recursos y el historial de trabajos. Para retirarlo
# después, con el estado de esta ejecución:
#   ./24_undeploy_docker_compose.sh
#   E2E_CONFIRM_DOCKER_PURGE=YES ./25_uninstall_docker.sh
# o bien ./98_reset.sh para dejar AWX y el destino como recién instalados.
#
# No pide confirmación porque no purga nada, pero 20 se niega a continuar si el
# destino ya tiene nginx, Docker o sus datos.
set -euo pipefail
cd "$(dirname "$0")"

./80_deploy_awx_with_examples.sh
rm -rf .e2e-state/webserver_* .e2e-state/target_docker_was_clean .e2e-state/docker_* \
    .e2e-state/container_* .e2e-state/compose_* .e2e-state/last_job_id
./18_install_webserver.sh
./19_uninstall_webserver.sh
./20_install_docker.sh
./21_deploy_docker_container.sh
./22_undeploy_docker_container.sh
./23_deploy_docker_compose.sh
echo 'E2E completo sin limpieza: AWX, Docker y el stack de Compose siguen desplegados.'
echo 'Para retirarlos: ./24_undeploy_docker_compose.sh y E2E_CONFIRM_DOCKER_PURGE=YES ./25_uninstall_docker.sh'
