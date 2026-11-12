#!/usr/bin/env bash
# Instala Docker con la plantilla instalar-docker-laboratorio. Se niega a
# continuar si el destino ya tiene Docker o sus datos.
set -euo pipefail
source "$(dirname "$0")/scripts/lib_awx_e2e.sh"

[[ -s "$E2E_STATE_DIR/webserver_uninstalled" ]] || { echo 'Ejecuta primero ./19_uninstall_webserver.sh.' >&2; exit 1; }

remote_ssh 'for p in docker-ce docker-ce-cli containerd.io docker.io docker-compose docker-compose-v2; do s="$(dpkg-query -W -f="\${db:Status-Status}" "$p" 2>/dev/null || true)"; [ "$s" != installed ] || { echo "Paquete Docker preexistente: $p" >&2; exit 20; }; done; for d in /var/lib/docker /var/lib/containerd /etc/docker; do [ ! -e "$d" ] || { echo "Datos Docker preexistentes: $d" >&2; exit 21; }; done'
printf 'target_docker_was_clean\n' > "$E2E_STATE_DIR/target_docker_was_clean"
api_login "$E2E_USER_LOGIN" "$E2E_USER_PASSWORD"
run_template 'instalar-docker-laboratorio'
remote_root 'docker info --format "Docker={{.ServerVersion}}"'
printf 'docker_installed\n' > "$E2E_STATE_DIR/docker_installed"
