#!/bin/bash
# Para y elimina el despliegue de prueba (proyecto Compose
# "demo-compose-app"). Paso manual: el Jenkinsfile no se autodestruye el
# despliegue que acaba de hacer.
set -e
CONTAINERS="$(docker ps -aq --filter "label=com.docker.compose.project=demo-compose-app")"
if [ -z "$CONTAINERS" ]; then
  echo "No hay ningun contenedor del proyecto 'demo-compose-app' en marcha."
  exit 0
fi
docker rm -f $CONTAINERS
docker network rm demo-compose-app_default 2>/dev/null || true
echo "Despliegue 'demo-compose-app' parado y eliminado."
