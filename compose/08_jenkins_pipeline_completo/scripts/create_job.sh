#!/bin/bash
# Da de alta (o actualiza si ya existe) un job de tipo pipeline en Jenkins,
# a partir del contenido de jenkinsfile/<nombre-ejemplo>/Jenkinsfile
set -e
cd "$(dirname "$0")/.."

NAME="$1"
if [ -z "$NAME" ]; then
  echo "Uso: $0 <nombre-ejemplo>   (debe existir jenkinsfile/<nombre-ejemplo>/Jenkinsfile)"
  exit 1
fi

JENKINSFILE="jenkinsfile/$NAME/Jenkinsfile"
if [ ! -f "$JENKINSFILE" ]; then
  echo "No existe $JENKINSFILE"
  exit 1
fi

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

CONFIG_XML=$(python3 - "$JENKINSFILE" "$NAME" <<'PYEOF'
import sys
import xml.sax.saxutils as sx

jenkinsfile_path, name = sys.argv[1], sys.argv[2]
script = open(jenkinsfile_path).read()
escaped = sx.escape(script)
print(f"""<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>Ejemplo de pipeline: {name}</description>
  <keepDependencies>false</keepDependencies>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script>{escaped}</script>
    <sandbox>true</sandbox>
  </definition>
  <disabled>false</disabled>
</flow-definition>""")
PYEOF
)

COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

CRUMB_JSON=$(curl -sf -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")

EXISTS=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" -b "$COOKIES" "$JENKINS_URL/job/$NAME/api/json")

if [ "$EXISTS" = "200" ]; then
  echo "El job '$NAME' ya existe, actualizando su configuración..."
  echo "$CONFIG_XML" | curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -H "Content-Type: application/xml;charset=UTF-8" \
    --data-binary @- "$JENKINS_URL/job/$NAME/config.xml" -o /dev/null -w "HTTP %{http_code}\n"
else
  echo "Creando el job '$NAME'..."
  echo "$CONFIG_XML" | curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" -H "Content-Type: application/xml;charset=UTF-8" \
    --data-binary @- "$JENKINS_URL/createItem?name=$NAME" -o /dev/null -w "HTTP %{http_code}\n"
fi

echo "Verlo en Jenkins: $JENKINS_URL/job/$NAME/"
echo "Para lanzarlo, ejecuta el 02_build.sh de la carpeta de este ejemplo."
