#!/bin/bash
# Comprueba que el nodo 'agent1' aparece online en el Jenkins controller
# (no solo que el contenedor está arrancado)
set -e
cd "$(dirname "$0")"

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"
NODE_NAME="agent1"

echo "Esperando a que el nodo '$NODE_NAME' aparezca online en Jenkins..."
for i in $(seq 1 30); do
  STATUS=$(curl -sf -u "$AUTH" "$JENKINS_URL/computer/$NODE_NAME/api/json" 2>/dev/null || echo '{}')
  OFFLINE=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('offline'))" 2>/dev/null)
  if [ "$OFFLINE" = "False" ]; then
    echo "El nodo '$NODE_NAME' está online."
    exit 0
  fi
  sleep 2
done

echo "El nodo '$NODE_NAME' no ha conectado a tiempo."
echo "Revisa 'docker logs jenkins_docker_pipeline_agent' y"
echo "'docker logs jenkins_docker_pipeline' para ver el motivo."
exit 1
