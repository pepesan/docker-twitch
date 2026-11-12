#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LXC_NAME="${ANSIBLE_LXC_NAME:-lxd-vm-auto}"
LXC_IP="${ANSIBLE_LXC_IP:-10.207.154.161}"
STATE_DIR="$SCRIPT_DIR/config/ansible-e2e"
STATE_FILE="$STATE_DIR/state.env"
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
DEPLOY_EXAMPLES=(
  70_ansible_webserver
  72_ansible_docker_install
  73_ansible_docker_mariadb
  75_ansible_docker_compose_mariadb
)

if [[ -e "$STATE_FILE" ]]; then
  echo "Ya existe estado E2E en $STATE_FILE. Ejecuta ./99_destroy_ansible_e2e.sh antes de repetirlo." >&2
  exit 1
fi
command -v lxc >/dev/null || { echo "ERROR: no se encuentra lxc." >&2; exit 1; }
if ! INSTANCE_NAMES="$(lxc list "$LXC_NAME" --format csv --columns n 2>&1)"; then
  echo "ERROR: no se pudo consultar la instancia LXD '$LXC_NAME': $INSTANCE_NAMES" >&2
  exit 1
fi
if [[ "$INSTANCE_NAMES" != "$LXC_NAME" ]]; then
  echo "ERROR: no existe la instancia LXD '$LXC_NAME'." >&2
  exit 1
fi
lxc exec "$LXC_NAME" -- true >/dev/null
TARGET_IPS="$(lxc exec "$LXC_NAME" -- hostname -I)"
if [[ " $TARGET_IPS " != *" $LXC_IP "* ]]; then
  echo "ERROR: '$LXC_NAME' no tiene la IP $LXC_IP (IPs: $TARGET_IPS)." >&2
  exit 1
fi

NGINX_PACKAGE="$(lxc exec "$LXC_NAME" -- dpkg-query -W '-f=${db:Status-Status}' nginx 2>/dev/null || true)"
BASELINE_NGINX_INSTALLED=false
[[ "$NGINX_PACKAGE" == installed ]] && BASELINE_NGINX_INSTALLED=true
BASELINE_NGINX_ACTIVE="$(lxc exec "$LXC_NAME" -- systemctl is-active nginx 2>/dev/null || true)"
BASELINE_NGINX_ENABLED="$(lxc exec "$LXC_NAME" -- systemctl is-enabled nginx 2>/dev/null || true)"

BASELINE_DOCKER_PRESENT=false
if lxc exec "$LXC_NAME" -- sh -lc 'command -v docker >/dev/null 2>&1' 2>/dev/null; then
  BASELINE_DOCKER_PRESENT=true
  if ! lxc exec "$LXC_NAME" -- docker info >/dev/null; then
    echo "ERROR: Docker existe pero no está operativo; no se inicia el E2E." >&2
    exit 1
  fi
  for container in mariadb mariadb-compose adminer-compose; do
    if lxc exec "$LXC_NAME" -- docker container inspect "$container" >/dev/null 2>&1; then
      echo "ERROR: el contenedor '$container' ya existe; no se sobrescribe un recurso ajeno al E2E." >&2
      exit 1
    fi
  done
  for volume in mariadb-data-volume deploy-mariadb_mariadb_data; do
    if lxc exec "$LXC_NAME" -- docker volume inspect "$volume" >/dev/null 2>&1; then
      echo "ERROR: el volumen '$volume' ya existe; no se sobrescriben datos ajenos al E2E." >&2
      exit 1
    fi
  done
  if lxc exec "$LXC_NAME" -- test -e /home/alumno/deploy-mariadb; then
    echo "ERROR: ya existe /home/alumno/deploy-mariadb; no se sobrescriben ficheros ajenos al E2E." >&2
    exit 1
  fi
else
  for data_path in /var/lib/docker /var/lib/containerd /etc/docker; do
    if lxc exec "$LXC_NAME" -- test -e "$data_path"; then
      echo "ERROR: '$data_path' existe aunque docker no esté instalado; no es seguro que el destroy lo borre." >&2
      exit 1
    fi
  done
fi

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"
{
  printf 'LXC_NAME=%q\n' "$LXC_NAME"
  printf 'LXC_IP=%q\n' "$LXC_IP"
  printf 'BASELINE_NGINX_INSTALLED=%q\n' "$BASELINE_NGINX_INSTALLED"
  printf 'BASELINE_NGINX_ACTIVE=%q\n' "$BASELINE_NGINX_ACTIVE"
  printf 'BASELINE_NGINX_ENABLED=%q\n' "$BASELINE_NGINX_ENABLED"
  printf 'BASELINE_DOCKER_PRESENT=%q\n' "$BASELINE_DOCKER_PRESENT"
} > "$STATE_FILE"
chmod 600 "$STATE_FILE"
export ANSIBLE_LXC_NAME="$LXC_NAME" ANSIBLE_LXC_IP="$LXC_IP"

echo "==> Preparar credenciales Ansible"
"$SCRIPT_DIR/14_create_ansible_credentials.sh"

echo "==> Crear o actualizar los jobs Ansible 70–77"
for example in "${ALL_EXAMPLES[@]}"; do
  "$SCRIPT_DIR/jenkinsfile/$example/01_create.sh"
done

for example in "${DEPLOY_EXAMPLES[@]}"; do
  example_dir="$SCRIPT_DIR/jenkinsfile/$example"
  echo "==> Desplegar E2E Ansible: $example"
  "$example_dir/02_build.sh"
  "$example_dir/03_check.sh"
done

echo "E2E Ansible completado. Los servicios y los jobs 70–77 permanecen desplegados."
echo "Para retirarlos y restaurar el estado inicial: ./99_destroy_ansible_e2e.sh"
