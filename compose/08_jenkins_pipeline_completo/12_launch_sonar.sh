#!/bin/bash
# Opcional. Levanta SonarQube (perfil "sonar" de compose.yaml) para análisis de código.
set -e
cd "$(dirname "$0")"

# Comprobar el requisito de vm.max_map_count para Elasticsearch
MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || cat /proc/sys/vm/max_map_count 2>/dev/null || echo 0)
if [ "$MAP_COUNT" -lt 262144 ]; then
  echo "==> ADVERTENCIA: vm.max_map_count es $MAP_COUNT (requerido >= 262144 para SonarQube/Elasticsearch)."
  echo "    Es muy probable que el contenedor de SonarQube falle al arrancar."
  echo "    Puedes corregirlo temporalmente ejecutando en el host:"
  echo "      sudo sysctl -w vm.max_map_count=262144"
  echo
fi

mkdir -p ./sonar_data ./sonar_extensions ./sonar_logs
chmod -R 777 ./sonar_data ./sonar_extensions ./sonar_logs 2>/dev/null || true

docker compose -p jenkins_docker_pipeline --profile sonar up -d

SONAR_URL="http://localhost:9005"

echo
echo "SonarQube arrancando (puede tardar 1-2 minutos en iniciar)."
echo "  UI:          $SONAR_URL"
echo "  Usuario:     admin"
echo "  Password:    admin (inicial, se cambiará con ./13_setup_sonar.sh)"
echo
echo "Ejecuta ./13_setup_sonar.sh para esperar a que esté listo, configurar"
echo "la contraseña de admin, generar el token e insertarlo en Jenkins."
