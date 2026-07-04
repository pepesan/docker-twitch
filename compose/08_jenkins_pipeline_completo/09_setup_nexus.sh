#!/bin/bash
# Espera a que Nexus esté listo y lo configura por completo sin pasos
# manuales por la UI: cambia la contraseña inicial (aleatoria) por una
# fija, acepta el EULA de la Community Edition, activa el realm de tokens
# Docker (necesario para "docker login") y crea los repositorios
# "maven-hosted" y "docker-hosted" si no existen. Idempotente.
set -e
cd "$(dirname "$0")"

NEXUS_URL="${NEXUS_URL:-http://localhost:8083}"
NEXUS_ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD:-admin123}"

echo "Esperando a que Nexus responda..."
for i in $(seq 1 40); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$NEXUS_URL/service/rest/v1/status" 2>/dev/null || echo "000")
  if [ "$CODE" = "200" ]; then break; fi
  sleep 5
done
if [ "$CODE" != "200" ]; then
  echo "Nexus no respondió a tiempo."
  exit 1
fi

# La contraseña inicial (aleatoria) solo existe la primera vez que arranca
if [ -f ./nexus_data/admin.password ]; then
  INITIAL_PW=$(cat ./nexus_data/admin.password)
  echo "Cambiando la contraseña inicial de Nexus..."
  curl -sf -u "admin:$INITIAL_PW" -X PUT -H "Content-Type: text/plain" \
    --data "$NEXUS_ADMIN_PASSWORD" \
    "$NEXUS_URL/service/rest/v1/security/users/admin/change-password" -o /dev/null
else
  echo "La contraseña de admin ya se había configurado antes."
fi

AUTH="admin:$NEXUS_ADMIN_PASSWORD"

# Aceptar el EULA (Community Edition) si aún no se ha aceptado
ACCEPTED=$(curl -sf -u "$AUTH" "$NEXUS_URL/service/rest/v1/system/eula" | python3 -c "import sys,json; print(json.load(sys.stdin)['accepted'])")
if [ "$ACCEPTED" != "True" ]; then
  echo "Aceptando el EULA de Nexus Community Edition..."
  EULA_JSON=$(curl -sf -u "$AUTH" "$NEXUS_URL/service/rest/v1/system/eula" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(json.dumps({'disclaimer': d['disclaimer'], 'accepted': True}))
")
  curl -sf -u "$AUTH" -X POST -H "Content-Type: application/json" \
    --data "$EULA_JSON" "$NEXUS_URL/service/rest/v1/system/eula" -o /dev/null
else
  echo "El EULA ya estaba aceptado."
fi

# Activar el realm de tokens Docker (necesario para 'docker login')
REALMS=$(curl -sf -u "$AUTH" "$NEXUS_URL/service/rest/v1/security/realms/active")
if echo "$REALMS" | grep -q "DockerToken"; then
  echo "El realm DockerToken ya estaba activo."
else
  echo "Activando el realm DockerToken..."
  curl -sf -u "$AUTH" -X PUT -H "Content-Type: application/json" \
    --data '["NexusAuthenticatingRealm","DockerToken"]' \
    "$NEXUS_URL/service/rest/v1/security/realms/active" -o /dev/null
fi

repo_exists() {
  curl -sf -u "$AUTH" "$NEXUS_URL/service/rest/v1/repositories/$1" >/dev/null 2>&1
}

if repo_exists "maven-hosted"; then
  echo "El repositorio 'maven-hosted' ya existe."
else
  echo "Creando el repositorio 'maven-hosted'..."
  curl -sf -u "$AUTH" -X POST -H "Content-Type: application/json" \
    "$NEXUS_URL/service/rest/v1/repositories/maven/hosted" \
    -d '{
      "name": "maven-hosted",
      "online": true,
      "storage": {"blobStoreName": "default", "strictContentTypeValidation": true, "writePolicy": "ALLOW"},
      "maven": {"versionPolicy": "MIXED", "layoutPolicy": "PERMISSIVE"}
    }' -o /dev/null
fi

if repo_exists "docker-hosted"; then
  echo "El repositorio 'docker-hosted' ya existe."
else
  echo "Creando el repositorio 'docker-hosted'..."
  curl -sf -u "$AUTH" -X POST -H "Content-Type: application/json" \
    "$NEXUS_URL/service/rest/v1/repositories/docker/hosted" \
    -d '{
      "name": "docker-hosted",
      "online": true,
      "storage": {"blobStoreName": "default", "strictContentTypeValidation": true, "writePolicy": "ALLOW"},
      "docker": {"v1Enabled": false, "forceBasicAuth": true, "httpPort": 8084}
    }' -o /dev/null
fi

# Registrar la credencial 'nexus-creds' en Jenkins, para que los ejemplos
# 31/32/33 puedan autenticarse contra Nexus sin repetir esta lógica
JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
JENKINS_AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

JENKINS_UP=$(curl -s -o /dev/null -w "%{http_code}" -u "$JENKINS_AUTH" "$JENKINS_URL/api/json" 2>/dev/null || echo "000")
if [ "$JENKINS_UP" = "200" ]; then
  CRED_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" -u "$JENKINS_AUTH" "$JENKINS_URL/credentials/store/system/domain/_/credential/nexus-creds/api/json")
  if [ "$CRED_EXISTS" = "200" ]; then
    echo "La credencial Jenkins 'nexus-creds' ya existe."
  else
    echo "Creando la credencial Jenkins 'nexus-creds'..."
    JCOOKIES=$(mktemp)
    JCRUMB_JSON=$(curl -sf -u "$JENKINS_AUTH" -c "$JCOOKIES" "$JENKINS_URL/crumbIssuer/api/json")
    JCRUMB=$(echo "$JCRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
    JFIELD=$(echo "$JCRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")
    CRED_JSON=$(python3 -c "
import json
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'nexus-creds',
    'username': 'admin',
    'password': '$NEXUS_ADMIN_PASSWORD',
    'description': 'Usuario admin de Nexus (registro Docker / repositorio Maven)',
    '\$class': 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl'
  }
}))
")
    curl -s -u "$JENKINS_AUTH" -b "$JCOOKIES" -H "$JFIELD: $JCRUMB" --data-urlencode "json=$CRED_JSON" \
      "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
    rm -f "$JCOOKIES"
  fi
else
  echo "Jenkins no está arrancado: omitiendo el alta de la credencial 'nexus-creds'."
  echo "Ejecuta ./01_launch.sh y vuelve a lanzar este script si la necesitas."
fi

echo
echo "Nexus listo:"
echo "  UI:               $NEXUS_URL"
echo "  Usuario:          admin"
echo "  Password:         $NEXUS_ADMIN_PASSWORD"
echo "  Repo Maven:       $NEXUS_URL/repository/maven-hosted/"
echo "  Repo Docker:      localhost:8084 (docker login localhost:8084 -u admin -p $NEXUS_ADMIN_PASSWORD)"
