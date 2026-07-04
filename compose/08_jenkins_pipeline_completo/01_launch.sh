#!/bin/bash
# Construye la imagen y levanta el Jenkins controller
set -e
cd "$(dirname "$0")"
docker compose -p jenkins_docker_pipeline up -d --build

echo
echo "Jenkins arrancando. Puede tardar unos segundos en estar listo."
echo "  URL:      http://localhost:8082"
echo "  Usuario:  ${JENKINS_ADMIN_ID:-admin}"
echo "  Password: ${JENKINS_ADMIN_PASSWORD:-admin}"
echo "Comprueba el estado con ./02_ps.sh o sigue los logs con ./03_logs.sh."
