#!/bin/bash
# Para y elimina el proyecto Compose en el host LXC remoto
set -e
cd "$(dirname "$0")/../.."
ssh -i ./config/ssh/id_ed25519 -o StrictHostKeyChecking=no root@10.207.154.80 "docker compose -f /tmp/compose-lxc.yaml -p demo-lxc-compose down 2>/dev/null || docker rm -f demo-lxc-compose-app-1 demo-lxc-compose-db-1 2>/dev/null || true"
echo "Despliegue 'demo-lxc-compose' en LXC parado y eliminado."
