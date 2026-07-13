#!/bin/bash
# Para y elimina el despliegue de prueba (blog-astro-deploy). Paso manual:
# el Jenkinsfile no se autodestruye el despliegue que acaba de hacer.
set -e
if ! docker ps -aq --filter "name=^blog-astro-deploy$" | grep -q .; then
  echo "No hay ningun contenedor 'blog-astro-deploy' en marcha."
  exit 0
fi
docker rm -f blog-astro-deploy
echo "Despliegue 'blog-astro-deploy' parado y eliminado."
