#!/usr/bin/env bash
# Uso: ./10_scale.sh <N>
# Cambia el número de execution nodes a N. Si N es menor que el actual,
# deprovisiona primero (en AWX) los nodos que van a desaparecer — el
# bootstrap de ansible/awx solo sabe añadir nodos nuevos solo, nunca
# borra registros de nodos retirados.
set -euo pipefail
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh

NEW_COUNT="${1:-}"
if [ -z "$NEW_COUNT" ] || ! [[ "$NEW_COUNT" =~ ^[0-9]+$ ]]; then
    echo "Uso: $0 <N>  (número de execution nodes deseado, entero >= 0)" >&2
    exit 1
fi

OLD_COUNT="${AWX_EXECUTION_NODE_COUNT}"

if [ "$NEW_COUNT" -lt "$OLD_COUNT" ]; then
    echo "Desescalando de ${OLD_COUNT} a ${NEW_COUNT}: deprovisionando receptor-$((NEW_COUNT + 1))..receptor-${OLD_COUNT}..."
    for ((k = NEW_COUNT + 1; k <= OLD_COUNT; k++)); do
        docker compose exec -T awx_1 awx-manage deprovision_instance --hostname="receptor-${k}" || true
    done
fi

sed -i "s/^AWX_EXECUTION_NODE_COUNT=.*/AWX_EXECUTION_NODE_COUNT=${NEW_COUNT}/" .env
source scripts/lib_load_env.sh

./scripts/02_build_image.sh
./scripts/04_generate_compose.sh

docker compose up -d --remove-orphans

echo
echo "Escalado a ${NEW_COUNT} execution nodes. Comprueba con:"
echo "  docker compose exec awx_1 awx-manage list_instances"
