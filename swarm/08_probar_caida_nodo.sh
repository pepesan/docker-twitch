#!/usr/bin/env bash
# Reproduce en vivo los diagramas "qué ocurre si cae un nodo" de la unidad
# de Swarm. 'lxc stop' simula un apagón real (a diferencia de
# 'docker node update --availability drain', que sería una salida ordenada):
# el resto del cluster deja de recibir heartbeats de ese nodo sin previo aviso.
#
# Caer un WORKER: sus tareas se reprograman en otro nodo Ready (el servicio
# sigue disponible, solo hay una breve interrupción de esa réplica).
#
# Caer un MANAGER: si sigue habiendo mayoría (2 de 3), el cluster sigue
# operativo y puede haber una nueva elección de líder si el caído era el
# líder. Prueba: ./08_probar_caida_nodo.sh manager1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

MANAGER1="${NODE_NAMES[0]}"
SERVICE_NAME="web-demo"
TARGET_NODE="${1:-${NODE_NAMES[-1]}}"

echo "==> Nodo a derribar: $TARGET_NODE (usa: $0 <nombre-nodo> para elegir otro)"
echo ""
echo "==> Estado del servicio ANTES de la caída:"
lxc exec "$MANAGER1" -- docker service ps "$SERVICE_NAME" --filter "desired-state=running"

echo ""
echo "==> Simulando la caída de $TARGET_NODE (lxc stop, equivale a un apagón)"
lxc stop "$TARGET_NODE"

echo "==> Esperando a que Swarm detecte el nodo caído y reprograme sus tareas..."
sleep 25

echo ""
echo "==> Nodos del cluster DESPUÉS de la caída:"
lxc exec "$MANAGER1" -- docker node ls

echo ""
echo "==> Tareas del servicio DESPUÉS de la caída (una debería reaparecer en otro nodo):"
lxc exec "$MANAGER1" -- docker service ps "$SERVICE_NAME"

echo ""
echo "==> Restaurando $TARGET_NODE"
lxc start "$TARGET_NODE"

echo "==> Esperando a que $TARGET_NODE vuelva a Ready..."
sleep 15
lxc exec "$MANAGER1" -- docker node ls
