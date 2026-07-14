#!/bin/bash
# Para y elimina el contenedor en el host LXC remoto
set -e
cd "$(dirname "$0")/../.."
ssh -i ./config/ssh/id_ed25519 -o StrictHostKeyChecking=no root@10.207.154.80 "docker rm -f demo-ansible-app 2>/dev/null || true"
echo "Despliegue 'demo-ansible-app' en LXC parado y eliminado."
