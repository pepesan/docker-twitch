#!/usr/bin/env bash
# Despliega un servicio replicado real para tener algo que romper en
# 08_probar_caida_nodo.sh. Con --replicas 3 y 5 nodos, Swarm reparte las
# réplicas entre distintos nodos automáticamente (no hay que decirle dónde).
#
# --constraint node.role==worker fuerza a que las réplicas caigan SOLO en
# workers: los managers deben quedar libres para el quórum Raft y no competir
# por CPU/memoria con la carga de aplicación — buena práctica de Swarm en
# producción, no solo cosa de este laboratorio.
#
# La prueba de las 5 IPs de después es la comprobación del routing mesh: el
# puerto 8080 está "publicado" en TODOS los nodos (managers incluidos, aunque
# no tengan ninguna réplica) — Swarm enruta internamente hasta una réplica activa.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

MANAGER1="${NODE_NAMES[0]}"
SERVICE_NAME="web-demo"

echo "==> Desplegando servicio '$SERVICE_NAME' con 3 réplicas (publicado en :8080, solo en workers)"
lxc exec "$MANAGER1" -- docker service create \
  --name "$SERVICE_NAME" \
  --replicas 3 \
  --constraint node.role==worker \
  --publish 8080:80 \
  nginx:stable-alpine

echo "==> Esperando a que las réplicas arranquen..."
sleep 10

echo "==> Estado del servicio:"
lxc exec "$MANAGER1" -- docker service ps "$SERVICE_NAME"

# Validar que el --constraint node.role==worker se cumplió de verdad: ninguna
# tarea en ejecución debe estar en un nombre de nodo que sea manager.
echo ""
echo "==> Validando que ninguna réplica corre en un manager..."
manager_names=()
for i in "${!NODE_NAMES[@]}"; do
  if [ "${NODE_ROLES[$i]}" = "manager" ]; then
    manager_names+=("${NODE_NAMES[$i]}")
  fi
done

fail=0
while IFS= read -r node; do
  [ -z "$node" ] && continue
  for m in "${manager_names[@]}"; do
    if [ "$node" = "$m" ]; then
      echo "ERROR: hay una réplica de $SERVICE_NAME corriendo en el manager $node" >&2
      fail=1
    fi
  done
done < <(lxc exec "$MANAGER1" -- docker service ps "$SERVICE_NAME" --filter "desired-state=running" --format '{{.Node}}')

if [ "$fail" -eq 1 ]; then
  exit 1
fi
echo "==> OK: las réplicas están solo en nodos worker."

echo ""
echo "==> Probando el routing mesh: la misma petición funciona desde cualquier nodo"
for i in "${!NODE_NAMES[@]}"; do
  ip="${NODE_IPS[$i]}"
  name="${NODE_NAMES[$i]}"
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://${ip}:8080/" || echo "sin respuesta")"
  echo "    http://$ip:8080/ ($name) -> HTTP $code"
done
