#!/usr/bin/env bash
# 'docker node ls' solo se puede ejecutar desde un manager (aquí manager1):
# los workers no tienen visión del estado global del cluster, solo el propio.
# Los 5 nodos deben aparecer en STATUS=Ready; manager1 con MANAGER STATUS=Leader
# y manager2/manager3 con Reachable (participan en el quórum pero no mandan).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

MANAGER1="${NODE_NAMES[0]}"

echo "==> Estado del cluster (desde $MANAGER1):"
lxc exec "$MANAGER1" -- docker node ls
