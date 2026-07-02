#!/usr/bin/env bash
# Une manager2 y manager3 al cluster ya creado por 03_swarm_init.sh, usando
# el token de manager guardado en manager.token. Con 3 managers, el cluster
# tolera la caída de 1 sin perder el quórum Raft (mayoría = 2 de 3) — ver
# 08_probar_caida_nodo.sh para comprobarlo en vivo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

MANAGER1="${NODE_NAMES[0]}"
MANAGER1_IP="${NODE_IPS[0]}"
TOKEN="$(cat manager.token)"

for i in "${!NODE_NAMES[@]}"; do
  name="${NODE_NAMES[$i]}"
  role="${NODE_ROLES[$i]}"
  if [ "$role" = "manager" ] && [ "$name" != "$MANAGER1" ]; then
    echo "==> Uniendo $name como manager"
    lxc exec "$name" -- docker swarm join --token "$TOKEN" "$MANAGER1_IP:2377"
  fi
done

echo "==> Managers adicionales unidos al cluster."
