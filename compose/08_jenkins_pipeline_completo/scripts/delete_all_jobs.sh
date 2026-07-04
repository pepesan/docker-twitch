#!/bin/bash
# Borra todos los jobs dados de alta en el Jenkins (reset "blando":
# limpia jobs pero deja el controller corriendo)
set -e
cd "$(dirname "$0")/.."

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

JOBS=$(curl -sf -u "$AUTH" "$JENKINS_URL/api/json" | python3 -c "import sys,json; print('\n'.join(j['name'] for j in json.load(sys.stdin)['jobs']))")

if [ -z "$JOBS" ]; then
  echo "No hay jobs dados de alta."
  exit 0
fi

echo "$JOBS" | while read -r NAME; do
  [ -z "$NAME" ] && continue
  ./scripts/delete_job.sh "$NAME"
done
