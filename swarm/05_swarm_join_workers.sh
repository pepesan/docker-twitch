#!/usr/bin/env bash
# Une worker1 y worker2 al cluster con el token de worker (worker.token):
# solo pueden ejecutar las tareas que les asignen los managers, no participan
# en el quórum Raft ni pueden gestionar el estado del cluster.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

MANAGER1_IP="${NODE_IPS[0]}"
TOKEN="$(cat worker.token)"

for i in "${!NODE_NAMES[@]}"; do
  name="${NODE_NAMES[$i]}"
  role="${NODE_ROLES[$i]}"
  if [ "$role" = "worker" ]; then
    echo "==> Uniendo $name como worker"
    lxc exec "$name" -- docker swarm join --token "$TOKEN" "$MANAGER1_IP:2377"
  fi
done

echo "==> Workers unidos al cluster."
