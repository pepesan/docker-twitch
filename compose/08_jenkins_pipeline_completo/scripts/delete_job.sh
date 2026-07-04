#!/bin/bash
# Borra un job de Jenkins por nombre, si existe
set -e
cd "$(dirname "$0")/.."

NAME="$1"
if [ -z "$NAME" ]; then
  echo "Uso: $0 <nombre-job>"
  exit 1
fi

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

EXISTS=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" "$JENKINS_URL/job/$NAME/api/json")
if [ "$EXISTS" != "200" ]; then
  echo "El job '$NAME' no existe, nada que borrar."
  exit 0
fi

CRUMB_JSON=$(curl -sf -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")

echo "Borrando el job '$NAME'..."
curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -X POST "$JENKINS_URL/job/$NAME/doDelete" -o /dev/null -w "HTTP %{http_code}\n"
