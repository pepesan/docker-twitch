#!/bin/bash
# Para y elimina el contenedor en el host LXC remoto a través de la API Docker TLS
set -e
cd "$(dirname "$0")/../.."

export DOCKER_HOST="tcp://10.207.154.80:2376"
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH="./config/certs"

if docker ps -aq --filter "name=^demo-lxc-tls-app$" | grep -q .; then
  docker rm -f demo-lxc-tls-app
  echo "Despliegue 'demo-lxc-tls-app' en LXC (vía TLS) parado y eliminado."
else
  echo "No hay ningún contenedor 'demo-lxc-tls-app' en marcha."
fi
