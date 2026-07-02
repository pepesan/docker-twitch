#!/usr/bin/env bash
# Borra los contenedores LXD del laboratorio ('lxc delete -f' los para y
# elimina de un golpe, sin pasar por un apagado ordenado). No queda estado
# a medias: el cluster Swarm entero desaparece con las máquinas.
# Incluye también portainer-server (creado por 09), si existe.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

echo "ATENCIÓN: esto eliminará los 5 contenedores LXD del cluster Swarm, el nodo"
echo "portainer-server (si existe) y todos sus datos"
read -rp "¿Estás seguro? Escribe 'si' para confirmar: " confirm

if [ "$confirm" != "si" ]; then
  echo "Cancelado."
  exit 0
fi

for name in "${NODE_NAMES[@]}" portainer-server; do
  if lxc info "$name" &>/dev/null; then
    echo "==> Eliminando $name"
    lxc delete -f "$name"
  fi
done

rm -f manager.token worker.token

echo "==> Destrucción completada."
