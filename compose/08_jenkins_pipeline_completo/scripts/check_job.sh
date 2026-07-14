#!/bin/bash
# Comprueba el estado y muestra el log completo del último build del job
set -e
cd "$(dirname "$0")/.."

NAME="$1"
if [ -z "$NAME" ]; then
  echo "Uso: $0 <nombre-ejemplo>"
  exit 1
fi

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

# Verificar si Jenkins responde antes de continuar
if ! curl -sf -o /dev/null -u "$AUTH" "$JENKINS_URL/api/json"; then
  echo "Error: No se pudo conectar a Jenkins en $JENKINS_URL (o las credenciales no son válidas)."
  echo "Asegúrate de que Jenkins esté levantado (puedes iniciarlo con ./01_launch.sh)."
  exit 1
fi

# Obtener información del último build
BUILD_INFO=$(curl -sf -u "$AUTH" "$JENKINS_URL/job/$NAME/lastBuild/api/json" 2>/dev/null || echo "")

if [ -z "$BUILD_INFO" ]; then
  echo "No se encontró ningún build para el job '$NAME' (o el job no existe)."
  exit 1
fi

BUILD_NUM=$(echo "$BUILD_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['number'])")
RESULT=$(echo "$BUILD_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result'))")
BUILDING=$(echo "$BUILD_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('building'))")

echo "--------------------------------------------------"
echo "Job: $NAME | Build: #$BUILD_NUM"
echo "Estado actual: $( [ "$BUILDING" = "True" ] && echo "EN EJECUCIÓN" || echo "$RESULT" )"
echo "--------------------------------------------------"
echo "--- LOG DE CONSOLA COMPLETO ---"
curl -s -u "$AUTH" "$JENKINS_URL/job/$NAME/$BUILD_NUM/consoleText"
echo "--------------------------------------------------"
echo "URL en Jenkins: $JENKINS_URL/job/$NAME/$BUILD_NUM/console"

[ "$RESULT" = "SUCCESS" ]
