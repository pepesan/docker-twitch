#!/bin/bash
# Para y elimina el proyecto Compose en el host LXC remoto
set -e
cd "$(dirname "$0")/../.."
# Comprobar si el host LXC remoto está operativo
LXC_RUNNING=false
if command -v lxc &>/dev/null; then
  if lxc info jenkins-external-docker 2>/dev/null | grep -q "Status: RUNNING"; then
    LXC_RUNNING=true
  fi
fi
if [ "$LXC_RUNNING" = "false" ] && ping -c 1 -W 1 10.207.154.80 &>/dev/null; then
  LXC_RUNNING=true
fi
if [ "$LXC_RUNNING" = "false" ]; then
  echo "El host remoto LXC (10.207.154.80) no está en marcha. Saltando parada."
  exit 0
fi

ssh -i ./config/ssh/id_ed25519 -o ConnectTimeout=2 -o ConnectionAttempts=1 -o StrictHostKeyChecking=no root@10.207.154.80 "docker compose -f /tmp/compose-lxc.yaml -p demo-lxc-compose down 2>/dev/null || docker rm -f demo-lxc-compose-app-1 demo-lxc-compose-db-1 2>/dev/null || true"
echo "Despliegue 'demo-lxc-compose' en LXC parado y eliminado."
