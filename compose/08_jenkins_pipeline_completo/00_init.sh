#!/bin/bash
# Prepara los directorios de volúmenes antes de lanzar los contenedores
set -e
cd "$(dirname "$0")"
mkdir -p ./jenkins_home
chmod -R 777 ./jenkins_home 2>/dev/null || true

echo "Listo. Ahora ejecuta ./01_launch.sh para construir y arrancar el Jenkins controller."
