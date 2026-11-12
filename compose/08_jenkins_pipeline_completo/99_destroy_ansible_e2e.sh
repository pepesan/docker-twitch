#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$SCRIPT_DIR/config/ansible-e2e/state.env"
if [[ ! -f "$STATE_FILE" ]]; then
  echo "No hay estado E2E de Ansible en $STATE_FILE." >&2
  exit 1
fi
# El archivo solo lo genera 98_test_ansible_pipelines.sh y tiene permisos 0600.
# shellcheck disable=SC1090
source "$STATE_FILE"
: "${LXC_NAME:?Falta LXC_NAME en el estado E2E}"
: "${LXC_IP:?Falta LXC_IP en el estado E2E}"
: "${BASELINE_NGINX_INSTALLED:?Falta estado inicial de Nginx}"
: "${BASELINE_NGINX_ACTIVE:?Falta estado inicial de Nginx}"
: "${BASELINE_NGINX_ENABLED:?Falta estado inicial de Nginx}"
: "${BASELINE_DOCKER_PRESENT:?Falta estado inicial de Docker}"

command -v lxc >/dev/null || { echo "ERROR: no se encuentra lxc." >&2; exit 1; }
lxc exec "$LXC_NAME" -- true >/dev/null
export ANSIBLE_LXC_NAME="$LXC_NAME" ANSIBLE_LXC_IP="$LXC_IP"

run_job() {
  local example="$1"
  local job_dir="$SCRIPT_DIR/jenkinsfile/$example"
  "$job_dir/01_create.sh"
  "$job_dir/02_build.sh"
  "$job_dir/03_check.sh"
}

docker_available=false
if lxc exec "$LXC_NAME" -- sh -lc 'command -v docker >/dev/null 2>&1'; then
  docker_available=true
fi

if [[ "$docker_available" == true ]]; then
  echo "==> Retirar los despliegues E2E presentes"
  compose_needed=false
  for container in mariadb-compose adminer-compose; do
    if lxc exec "$LXC_NAME" -- docker container inspect "$container" >/dev/null 2>&1; then
      compose_needed=true
    fi
  done
  if lxc exec "$LXC_NAME" -- test -e /home/alumno/deploy-mariadb; then
    compose_needed=true
  fi
  if [[ "$compose_needed" == true ]]; then
    run_job 76_ansible_docker_compose_mariadb_uninstall
  else
    echo "Compose del E2E ya está retirado."
  fi
  if lxc exec "$LXC_NAME" -- docker container inspect mariadb >/dev/null 2>&1; then
    run_job 74_ansible_docker_mariadb_uninstall
  else
    echo "Contenedor MariaDB directo del E2E ya está retirado."
  fi
fi

if [[ "$BASELINE_NGINX_INSTALLED" == true ]]; then
  current_nginx="$(lxc exec "$LXC_NAME" -- dpkg-query -W '-f=${db:Status-Status}' nginx 2>/dev/null || true)"
  if [[ "$current_nginx" == installed ]]; then
    echo "==> Restaurar el estado inicial de Nginx; el paquete ya existía antes del E2E"
    if [[ "$BASELINE_NGINX_ACTIVE" == active ]]; then
      lxc exec "$LXC_NAME" -- systemctl start nginx
    else
      lxc exec "$LXC_NAME" -- systemctl stop nginx >/dev/null 2>&1 || true
    fi
    case "$BASELINE_NGINX_ENABLED" in
      enabled) lxc exec "$LXC_NAME" -- systemctl enable nginx >/dev/null ;;
      disabled) lxc exec "$LXC_NAME" -- systemctl disable nginx >/dev/null ;;
    esac
  else
    echo "AVISO: Nginx ya no está instalado; no se puede restaurar su estado inicial." >&2
  fi
else
  current_nginx="$(lxc exec "$LXC_NAME" -- dpkg-query -W '-f=${db:Status-Status}' nginx 2>/dev/null || true)"
  if [[ "$current_nginx" == installed ]]; then
    echo "==> Retirar Nginx instalado por el E2E"
    run_job 71_ansible_webserver_uninstall
  fi
fi

if [[ "$docker_available" == true ]]; then
  echo "==> Eliminar los volúmenes MariaDB propios del E2E"
  for volume in mariadb-data-volume deploy-mariadb_mariadb_data; do
    if lxc exec "$LXC_NAME" -- docker volume inspect "$volume" >/dev/null 2>&1; then
      lxc exec "$LXC_NAME" -- docker volume rm "$volume"
    fi
  done
fi

if [[ "$BASELINE_DOCKER_PRESENT" == false && "$docker_available" == true ]]; then
  containers="$(lxc exec "$LXC_NAME" -- docker container ls -aq)"
  volumes="$(lxc exec "$LXC_NAME" -- docker volume ls -q)"
  images="$(lxc exec "$LXC_NAME" -- docker image ls --format '{{.Repository}}:{{.Tag}}')"
  unexpected_images="$(printf '%s\n' "$images" | grep -Ev '^(mariadb:latest|adminer:latest)$' || true)"
  if [[ -n "$containers" || -n "$volumes" || -n "$unexpected_images" ]]; then
    echo "ERROR: hay contenedores, volúmenes o imágenes ajenos al E2E; se conservan Docker y el estado E2E para evitar borrarlos." >&2
    printf 'Contenedores restantes: %s\nVolúmenes restantes: %s\nOtras imágenes: %s\n' \
      "${containers:-ninguno}" "${volumes:-ninguno}" "${unexpected_images:-ninguna}" >&2
    exit 1
  fi
  echo "==> Docker no existía antes del E2E; retirarlo ahora es seguro tras validar sus recursos"
  docker_uninstall_dir="$SCRIPT_DIR/jenkinsfile/77_ansible_docker_uninstall"
  "$docker_uninstall_dir/01_create.sh"
  CONFIRM_DOCKER_UNINSTALL=YES "$docker_uninstall_dir/02_build.sh"
  "$docker_uninstall_dir/03_check.sh"
fi

ALL_EXAMPLES=(
  70_ansible_webserver
  71_ansible_webserver_uninstall
  72_ansible_docker_install
  73_ansible_docker_mariadb
  74_ansible_docker_mariadb_uninstall
  75_ansible_docker_compose_mariadb
  76_ansible_docker_compose_mariadb_uninstall
  77_ansible_docker_uninstall
)
for example in "${ALL_EXAMPLES[@]}"; do
  "$SCRIPT_DIR/jenkinsfile/$example/04_delete.sh"
done

rm -f "$STATE_FILE"
rmdir "$SCRIPT_DIR/config/ansible-e2e" 2>/dev/null || true
echo "E2E Ansible destruido. Se conservaron las credenciales globales de Jenkins."
