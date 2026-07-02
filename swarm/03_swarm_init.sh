#!/usr/bin/env bash
# Convierte manager1 en el primer (y de momento único) nodo del cluster
# Swarm. --advertise-addr es obligatorio aquí porque el contenedor tiene
# varias interfaces (eth0, docker0, docker_gwbridge...); sin indicarlo, Swarm
# podría anunciar la IP equivocada y el resto de nodos no podrían unirse.
#
# docker swarm init genera DOS tokens distintos (uno para managers, otro para
# workers) porque dan permisos distintos al unirse: un token de manager
# permite escribir en el estado del cluster (Raft), uno de worker no.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

MANAGER1="${NODE_NAMES[0]}"
MANAGER1_IP="${NODE_IPS[0]}"

echo "==> Inicializando Swarm en $MANAGER1 ($MANAGER1_IP)"
lxc exec "$MANAGER1" -- docker swarm init --advertise-addr "$MANAGER1_IP"

echo "==> Guardando tokens de unión (manager.token, worker.token)"
lxc exec "$MANAGER1" -- docker swarm join-token -q manager > manager.token
lxc exec "$MANAGER1" -- docker swarm join-token -q worker > worker.token

echo "==> Cluster inicializado. $MANAGER1 es el líder."
