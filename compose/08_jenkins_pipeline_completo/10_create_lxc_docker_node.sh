#!/usr/bin/env bash
# Script 10: Crea y configura el contenedor LXC con soporte Docker.
set -euo pipefail

NODE_NAME="jenkins-external-docker"
FIXED_IP="10.207.154.80"
IMAGE="ubuntu-2404-ssh-template"
KERNEL_MODULES="ip_vs,ip_vs_rr,ip_vs_wrr,ip_vs_sh,ip_tables,ip6_tables,netlink_diag,nf_nat,overlay,br_netfilter"

echo "==> Iniciando creación del nodo LXC: $NODE_NAME"

if lxc info "$NODE_NAME" &>/dev/null; then
  echo "    [!] El contenedor $NODE_NAME ya existe. Asegurándose de que esté arrancado..."
  if [ "$(lxc info "$NODE_NAME" | grep "Status:" | awk '{print $2}')" != "RUNNING" ]; then
    lxc start "$NODE_NAME"
  fi
else
  echo "    [+] Creando contenedor LXC '$NODE_NAME' desde la plantilla '$IMAGE'..."
  lxc init "$IMAGE" "$NODE_NAME"

  echo "    [+] Configurando límites y red (IP fija: $FIXED_IP)..."
  lxc config set "$NODE_NAME" limits.cpu="2"
  lxc config set "$NODE_NAME" limits.memory="2GB"
  lxc config device override "$NODE_NAME" root size="20GB"
  lxc config device override "$NODE_NAME" eth0 ipv4.address="$FIXED_IP"

  echo "    [+] Aplicando directivas especiales de seguridad para Docker in LXC..."
  lxc config set "$NODE_NAME" security.nesting=true
  lxc config set "$NODE_NAME" security.privileged=true
  lxc config set "$NODE_NAME" linux.kernel_modules "$KERNEL_MODULES"

  echo "    [+] Arrancando el contenedor LXC..."
  lxc start "$NODE_NAME"
fi

echo "==> Esperando a que el nodo responda..."
for attempt in $(seq 1 30); do
  if lxc exec "$NODE_NAME" -- true &>/dev/null; then
    echo "    [OK] Contenedor $NODE_NAME listo e inicializado."
    lxc list "$NODE_NAME"
    exit 0
  fi
  sleep 2
done

echo "ERROR: El contenedor $NODE_NAME no respondió a tiempo." >&2
exit 1
