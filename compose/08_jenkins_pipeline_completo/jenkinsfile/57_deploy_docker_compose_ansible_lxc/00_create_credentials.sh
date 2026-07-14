#!/bin/bash
# Crea la credencial 'lxc-server-ip' en Jenkins de forma idempotente.
set -e
cd "$(dirname "$0")"

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

CRUMB_JSON=$(curl -sf -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")

exists() {
  local ID="$1"
  local CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" "$JENKINS_URL/credentials/store/system/domain/_/credential/$ID/api/json")
  [ "$CODE" = "200" ]
}

if exists "lxc-server-ip"; then
  echo "La credencial 'lxc-server-ip' ya existe."
else
  echo "Creando la credencial 'lxc-server-ip' (texto secreto con la IP del LXC)..."
  JSON=$(python3 -c "
import json
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'lxc-server-ip',
    'secret': '10.207.154.80',
    'description': 'IP del servidor LXC externo',
    '\$class': 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl'
  }
}))
")
  curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" --data-urlencode "json=$JSON" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
fi
