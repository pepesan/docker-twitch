#!/bin/bash
# Lanza un build de este job y, en cuanto llega a la ultima stage (el
# "input" manual), lo aprueba marcando DESTRUIR=true -- a diferencia de
# 02_build.sh (via build_job.sh generico), que aprueba cualquier input
# pendiente con sus valores por defecto (DESTRUIR=false), asi que nunca
# destruye el despliegue. Este script hace lo contrario a proposito: para
# destruir el despliegue DESDE EL PROPIO PIPELINE, no con docker directo
# (eso es lo que hace 04_stop_deploy.sh).
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

CRUMB_JSON=$(curl -sf -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")

NEXT_BUILD=$(curl -sf -u "$AUTH" "$JENKINS_URL/job/$NAME/api/json" | python3 -c "import sys,json; print(json.load(sys.stdin)['nextBuildNumber'])")

curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -X POST "$JENKINS_URL/job/$NAME/build" -o /dev/null -w "Build #$NEXT_BUILD encolado, HTTP %{http_code}\n"

echo "Esperando a que el build #$NEXT_BUILD llegue a la stage de destruccion..."
INPUT_ID=""
for i in $(seq 1 60); do
  BUILD_JSON=$(curl -sf -u "$AUTH" "$JENKINS_URL/job/$NAME/$NEXT_BUILD/api/json?depth=2" 2>/dev/null || echo '{}')
  INPUT_ID=$(echo "$BUILD_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for a in d.get('actions', []):
    if 'InputAction' in a.get('_class', ''):
        for e in a.get('executions', []):
            print(e['id'])
            break
" 2>/dev/null || true)
  if [ -n "$INPUT_ID" ]; then break; fi

  BUILDING=$(echo "$BUILD_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('building'))" 2>/dev/null)
  if [ "$BUILDING" = "False" ]; then
    echo "El build termino sin pasar por el input (revisa la consola)."
    exit 1
  fi
  sleep 3
done

if [ -z "$INPUT_ID" ]; then
  echo "Timeout esperando el input de la stage de destruccion."
  exit 1
fi

echo "Input pendiente ($INPUT_ID), aprobando con DESTRUIR=true..."
curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -X POST \
  --data-urlencode 'json={"parameter": [{"name": "DESTRUIR", "value": true}]}' \
  "$JENKINS_URL/job/$NAME/$NEXT_BUILD/input/$INPUT_ID/proceed" -o /dev/null -w "HTTP proceed: %{http_code}\n"

echo "Esperando a que termine el build..."
while true; do
  STATUS=$(curl -sf -u "$AUTH" "$JENKINS_URL/job/$NAME/$NEXT_BUILD/api/json" 2>/dev/null || echo '{}')
  BUILDING=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('building'))" 2>/dev/null)
  if [ "$BUILDING" = "False" ]; then break; fi
  sleep 3
done

RESULT=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result'))")
echo "Resultado: $RESULT"
echo "--- ultimas lineas de la consola ---"
curl -s -u "$AUTH" "$JENKINS_URL/job/$NAME/$NEXT_BUILD/consoleText" | tail -15
echo "Log completo: $JENKINS_URL/job/$NAME/$NEXT_BUILD/console"

[ "$RESULT" = "SUCCESS" ]
