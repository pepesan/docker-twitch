#!/bin/bash
# Para y elimina el contenedor en el host LXC remoto a través de la API Docker TLS
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

export DOCKER_HOST="tcp://10.207.154.80:2376"
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH="./config/certs"
export DOCKER_CLIENT_TIMEOUT=2
export COMPOSE_HTTP_TIMEOUT=2

if docker ps -aq --filter "name=^demo-lxc-tls-app$" | grep -q .; then
  docker rm -f demo-lxc-tls-app
  echo "Despliegue 'demo-lxc-tls-app' en LXC (vía TLS) parado y eliminado."
else
  echo "No hay ningún contenedor 'demo-lxc-tls-app' en marcha."
fi
