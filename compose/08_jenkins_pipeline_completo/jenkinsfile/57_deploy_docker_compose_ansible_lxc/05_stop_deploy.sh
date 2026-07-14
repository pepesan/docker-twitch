#!/bin/bash
# Para y elimina el proyecto Compose en el host LXC remoto
set -e
cd "$(dirname "$0")/../.."
ssh -i ./config/ssh/id_ed25519 -o StrictHostKeyChecking=no root@10.207.154.80 "docker compose -f /tmp/ansible-compose/compose.yaml -p demo-ansible-compose down 2>/dev/null || docker rm -f demo-ansible-compose-app-1 demo-ansible-compose-db-1 2>/dev/null || true"
echo "Despliegue 'demo-ansible-compose' en LXC parado y eliminado."
