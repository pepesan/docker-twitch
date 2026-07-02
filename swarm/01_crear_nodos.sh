#!/usr/bin/env bash
# Crea los 5 contenedores LXD que harán de "máquinas" del cluster Swarm.
#
# Docker (y sobre todo Swarm) dentro de un contenedor LXD no funciona con la
# configuración por defecto: hacen falta tres ajustes especiales, descubiertos
# a base de probar este laboratorio de verdad:
#   - security.nesting=true    -> permite ejecutar contenedores (los de Docker)
#     dentro de este contenedor LXD. Sin esto, runc falla al arrancar
#     cualquier contenedor con: "open sysctl net.ipv4.ip_unprivileged_port_start:
#     permission denied".
#   - linux.kernel_modules=... -> declara los módulos de kernel que dockerd
#     necesita (ip_vs para el routing mesh, overlay para las redes VXLAN...).
#   - security.privileged=true -> sin esto, /proc/sys/net/ipv4/vs/conntrack no
#     es visible dentro del contenedor y el routing mesh (docker service con
#     puertos publicados) falla al crear la red "ingress". Es un contenedor
#     con más privilegios de lo normal: válido para un laboratorio, no para
#     producción sin más precauciones.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

for i in "${!NODE_NAMES[@]}"; do
  name="${NODE_NAMES[$i]}"
  ip="${NODE_IPS[$i]}"
  cpu="${NODE_CPU[$i]}"
  mem="${NODE_MEM[$i]}"
  disk="${NODE_DISK[$i]}"

  if lxc info "$name" &>/dev/null; then
    echo "==> $name ya existe, se omite"
    continue
  fi

  echo "==> Creando $name (IP $ip, ${cpu} vCPU, ${mem} RAM, ${disk} disco)"

  # 'lxc init' crea el contenedor SIN arrancarlo todavía: así podemos aplicar
  # toda la configuración (recursos, IP fija, privilegios) antes del primer
  # arranque y evitar que se quede con una IP por DHCP equivocada.
  lxc init "$IMAGE" "$name"

  # Recursos: límites de CPU/RAM (cgroups) y tamaño del disco raíz (zfs)
  lxc config set "$name" limits.cpu="$cpu"
  lxc config set "$name" limits.memory="$mem"
  lxc config device override "$name" root size="$disk"

  # IP fija: LXD reserva esta IP en el DHCP de lxdbr0 para este contenedor
  lxc config device override "$name" eth0 ipv4.address="$ip"

  # Requisitos para que Docker Swarm funcione dentro del contenedor (ver
  # cabecera del script)
  lxc config set "$name" security.nesting=true
  lxc config set "$name" security.privileged=true
  lxc config set "$name" linux.kernel_modules="$KERNEL_MODULES"

  lxc start "$name"
done

echo "==> Esperando a que los nodos respondan..."
for name in "${NODE_NAMES[@]}"; do
  for attempt in $(seq 1 30); do
    if lxc exec "$name" -- true &>/dev/null; then
      break
    fi
    sleep 2
  done
  if ! lxc exec "$name" -- true &>/dev/null; then
    echo "ERROR: $name no responde tras esperar" >&2
    exit 1
  fi
  echo "    $name listo — $(lxc list "$name" --format csv -c 4)"
done

echo "==> Los 5 nodos están creados y accesibles."
