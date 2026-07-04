#!/bin/bash
# Lanza un build del job <nombre-ejemplo> y espera a que termine,
# mostrando el resultado y las últimas líneas de la consola. Si el
# Jenkinsfile tiene un "input" (aprobación manual), usar
# build_job_input.sh en su lugar -- este script no lo detecta ni lo
# aprueba, se quedaría esperando para siempre.
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
  sleep 5
done

RESULT=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result'))")
echo "Resultado: $RESULT"
echo "--- últimas líneas de la consola ---"
curl -s -u "$AUTH" "$JENKINS_URL/job/$NAME/$NEXT_BUILD/consoleText" | tail -40
echo "Log completo: $JENKINS_URL/job/$NAME/$NEXT_BUILD/console"

[ "$RESULT" = "SUCCESS" ]
