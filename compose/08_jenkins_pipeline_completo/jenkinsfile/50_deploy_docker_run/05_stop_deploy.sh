#!/bin/bash
# Para y elimina el contenedor desplegado por este ejemplo (demo-run-app).
# Paso manual: el Jenkinsfile no se autodestruye el despliegue que acaba
# de hacer.
set -e
if ! docker ps -aq --filter "name=^demo-run-app$" | grep -q .; then
  echo "No hay ningun contenedor 'demo-run-app' en marcha."
  exit 0
fi
docker rm -f demo-run-app
echo "Despliegue 'demo-run-app' parado y eliminado."
