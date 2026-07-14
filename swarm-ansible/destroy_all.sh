#!/usr/bin/env bash
# Desinstala Portainer y destruye el laboratorio completo de forma secuencial.
#
# Uso: ./destroy_all.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "════════════════════════════════════════════════════════════════"
echo "  [28] Desinstalar Portainer Agent del cluster Swarm"
echo "════════════════════════════════════════════════════════════════"
ansible-playbook 28_desinstalar_agente_portainer.yml

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  [29] Desinstalar Portainer Server"
echo "════════════════════════════════════════════════════════════════"
ansible-playbook 29_desinstalar_portainer.yml

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  [30] Destruir los nodos LXD y limpiar tokens"
echo "════════════════════════════════════════════════════════════════"
ansible-playbook 30_destroy.yml
