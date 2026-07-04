#!/bin/bash
# Para y elimina el despliegue de un entorno concreto (staging o
# produccion, por defecto staging). Paso manual: el Jenkinsfile no se
# autodestruye el despliegue que acaba de hacer.
set -e
ENTORNO="${1:-staging}"
PROJECT="demo-multientorno-${ENTORNO}"

CONTAINERS="$(docker ps -aq --filter "label=com.docker.compose.project=${PROJECT}")"
if [ -z "$CONTAINERS" ]; then
  echo "No hay ningun contenedor del proyecto '${PROJECT}' en marcha."
  exit 0
fi
docker rm -f $CONTAINERS
docker network rm "${PROJECT}_default" 2>/dev/null || true
echo "Despliegue '${PROJECT}' parado y eliminado."
