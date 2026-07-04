#!/bin/bash
# Opcional. Levanta Nexus OSS (perfil "nexus" de compose.yaml): registro
# Docker + repositorio Maven en un único servicio.
set -e
cd "$(dirname "$0")"

mkdir -p ./nexus_data
chmod -R 777 ./nexus_data 2>/dev/null || true

docker compose -p jenkins_docker_pipeline --profile nexus up -d

NEXUS_URL="http://localhost:8083"
NEXUS_ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD:-admin123}"

echo
echo "Nexus arrancando (puede tardar 1-2 minutos, es una JVM grande)."
echo "  UI:          $NEXUS_URL"
echo "  Repo Docker: localhost:8084"
echo "  Usuario:     admin"
echo "  Password:    aún no es \"$NEXUS_ADMIN_PASSWORD\" -- Nexus genera una"
echo "               aleatoria al arrancar; ./09_setup_nexus.sh la fija a"
echo "               esa y deja todo (EULA, repos, credencial Jenkins) listo."
echo
echo "Ejecuta ./09_setup_nexus.sh para esperar a que esté listo y crear"
echo "los repositorios Docker y Maven automáticamente."
