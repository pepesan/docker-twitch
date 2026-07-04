#!/bin/bash
# Variante de build_job.sh para los pocos ejemplos cuyo Jenkinsfile tiene
# un "input" (aprobación manual): además de esperar el build, detecta el
# input pendiente y lo aprueba solo, para poder verificarlos sin
# intervención manual. Se mantiene separado de build_job.sh a propósito
# -- esa logica no pinta nada en el script generico que usan el resto de
# ejemplos, que no tienen ningun input.
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

COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

CRUMB_JSON=$(curl -sf -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")

NEXT_BUILD=$(curl -sf -u "$AUTH" "$JENKINS_URL/job/$NAME/api/json" | python3 -c "import sys,json; print(json.load(sys.stdin)['nextBuildNumber'])")

curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -X POST "$JENKINS_URL/job/$NAME/build" -o /dev/null -w "Build #$NEXT_BUILD encolado, HTTP %{http_code}\n"

echo "Esperando a que termine el build #$NEXT_BUILD de '$NAME'..."
while true; do
  STATUS=$(curl -sf -u "$AUTH" "$JENKINS_URL/job/$NAME/$NEXT_BUILD/api/json" 2>/dev/null || echo '{}')
  BUILDING=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('building'))" 2>/dev/null)
  if [ "$BUILDING" = "False" ]; then break; fi

  # Si el pipeline está parado en un "input" pendiente, lo aprueba solo
  # (para poder verificar ejemplos con aprobación manual sin intervención)
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
  if [ -n "$INPUT_ID" ]; then
    echo "Input pendiente detectado ($INPUT_ID), aprobando automáticamente..."
    curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -X POST --data-urlencode "json={}" \
      "$JENKINS_URL/job/$NAME/$NEXT_BUILD/input/$INPUT_ID/proceed" -o /dev/null
  fi

  sleep 5
done

RESULT=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result'))")
echo "Resultado: $RESULT"
echo "--- últimas líneas de la consola ---"
curl -s -u "$AUTH" "$JENKINS_URL/job/$NAME/$NEXT_BUILD/consoleText" | tail -40
echo "Log completo: $JENKINS_URL/job/$NAME/$NEXT_BUILD/console"

[ "$RESULT" = "SUCCESS" ]
