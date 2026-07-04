#!/bin/bash
# Para y elimina el despliegue de prueba (proyecto Compose "demo-deploy")
# que deja vivo el build tras el pipeline. Paso manual: el Jenkinsfile no
# se autodestruye el despliegue que acaba de hacer.
set -e
CONTAINERS="$(docker ps -aq --filter "label=com.docker.compose.project=demo-deploy")"
if [ -z "$CONTAINERS" ]; then
  echo "No hay ningun contenedor del proyecto 'demo-deploy' en marcha."
  exit 0
fi
docker rm -f $CONTAINERS
echo "Despliegue 'demo-deploy' parado y eliminado."
