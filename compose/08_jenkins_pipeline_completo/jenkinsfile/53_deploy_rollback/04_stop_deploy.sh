#!/bin/bash
# Para y elimina el contenedor desplegado por este ejemplo
# (demo-rollback-app). Paso manual: el Jenkinsfile no se autodestruye el
# despliegue que acaba de hacer.
set -e
if ! docker ps -aq --filter "name=^demo-rollback-app$" | grep -q .; then
  echo "No hay ningun contenedor 'demo-rollback-app' en marcha."
  exit 0
fi
docker rm -f demo-rollback-app
echo "Despliegue 'demo-rollback-app' parado y eliminado."
