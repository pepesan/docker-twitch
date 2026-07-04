#!/bin/bash
# Da de alta en Jenkins la credencial (usuario/contraseña) con el token de
# GitLab para clonar el repo privado cursosdedesarrollo/blog. Lee
# GITLAB_BLOG_TOKEN de .env (copia .env.example a .env y rellena el token
# antes de ejecutar esto -- ver ese fichero para como generarlo).
# Idempotente: si la credencial ya existe, no la vuelve a crear.
set -e
cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "$GITLAB_BLOG_TOKEN" ]; then
  echo "Falta GITLAB_BLOG_TOKEN. Copia .env.example a .env, rellena el" >&2
  echo "token (ver instrucciones en ese fichero) y vuelve a ejecutar esto." >&2
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

CRED_ID="gitlab-blog-token"

exists() {
  local CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" "$JENKINS_URL/credentials/store/system/domain/_/credential/$CRED_ID/api/json")
  [ "$CODE" = "200" ]
}

if exists; then
  echo "La credencial '$CRED_ID' ya existe."
else
  echo "Creando la credencial '$CRED_ID' (usuario/contraseña, token GitLab)..."
  # GitLab acepta cualquier nombre de usuario junto al token por HTTPS
  # (convencion: "oauth2"); lo que importa de verdad es el token como
  # contraseña.
  JSON=$(python3 -c "
import json, os
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': '$CRED_ID',
    'username': 'oauth2',
    'password': os.environ['GITLAB_BLOG_TOKEN'],
    'description': 'Token de acceso a gitlab.com/cursosdedesarrollo/blog (repo privado)',
    '\$class': 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl'
  }
}))
")
  curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" --data-urlencode "json=$JSON" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
fi
