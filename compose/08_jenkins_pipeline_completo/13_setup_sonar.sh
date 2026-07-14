#!/bin/bash
# Espera a que SonarQube esté listo, cambia la contraseña del admin y crea la credencial en Jenkins
set -e
cd "$(dirname "$0")"

SONAR_URL="${SONAR_URL:-http://localhost:9005}"
SONAR_ADMIN_PASSWORD="${SONAR_ADMIN_PASSWORD:-admin123}"

echo "Esperando a que SonarQube responda..."
for i in $(seq 1 60); do
  # Intentar con admin/admin y admin/contraseña_nueva
  STATUS_JSON=$(curl -s -u "admin:admin" "$SONAR_URL/api/system/status" 2>/dev/null || \
                curl -s -u "admin:$SONAR_ADMIN_PASSWORD" "$SONAR_URL/api/system/status" 2>/dev/null || \
                echo "{}")
  STATUS=$(echo "$STATUS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
  
  if [ "$STATUS" = "UP" ]; then
    echo "¡SonarQube está activo!"
    break
  fi
  echo "SonarQube aún no está listo (estado: $STATUS)... esperando 5s"
  sleep 5
done

if [ "$STATUS" != "UP" ]; then
  echo "Error: SonarQube no respondió a tiempo."
  exit 1
fi

# Intentar cambiar la contraseña por si aún está la de por defecto
echo "Comprobando credenciales iniciales..."
if curl -sf -u "admin:admin" "$SONAR_URL/api/system/status" >/dev/null 2>&1; then
  echo "Cambiando la contraseña predeterminada de admin..."
  curl -sf -u "admin:admin" -X POST \
    "$SONAR_URL/api/users/change_password?login=admin&previousPassword=admin&password=$SONAR_ADMIN_PASSWORD" >/dev/null
  echo "Contraseña de admin cambiada correctamente."
else
  echo "La contraseña de admin ya se había configurado previamente."
fi

AUTH="admin:$SONAR_ADMIN_PASSWORD"

# Generar un token de análisis de forma idempotente (revocar si existe y volver a crear)
echo "Generando token de análisis de SonarQube..."
curl -s -u "$AUTH" -X POST "$SONAR_URL/api/user_tokens/revoke?name=jenkins-sonar-token" >/dev/null 2>&1 || true

TOKEN_JSON=$(curl -sf -u "$AUTH" -X POST "$SONAR_URL/api/user_tokens/generate?name=jenkins-sonar-token&type=USER_TOKEN")
SONAR_TOKEN=$(echo "$TOKEN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

if [ -z "$SONAR_TOKEN" ]; then
  echo "Error: No se pudo obtener el token de SonarQube."
  exit 1
fi
echo "Token generado con éxito."

# Registrar la credencial en Jenkins
JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
JENKINS_AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

echo "Verificando si Jenkins está activo..."
JENKINS_UP=$(curl -s -o /dev/null -w "%{http_code}" -u "$JENKINS_AUTH" "$JENKINS_URL/api/json" 2>/dev/null || echo "000")

if [ "$JENKINS_UP" = "200" ]; then
  # Obtener crumbs para Jenkins
  JCOOKIES=$(mktemp)
  trap 'rm -f "$JCOOKIES"' EXIT
  
  JCRUMB_JSON=$(curl -sf -u "$JENKINS_AUTH" -c "$JCOOKIES" "$JENKINS_URL/crumbIssuer/api/json")
  JCRUMB=$(echo "$JCRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
  JFIELD=$(echo "$JCRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")
  
  # Si existe el token anterior en Jenkins, lo borramos primero
  curl -s -u "$JENKINS_AUTH" -b "$JCOOKIES" -H "$JFIELD: $JCRUMB" -X POST \
    "$JENKINS_URL/credentials/store/system/domain/_/credential/sonar-token/doDelete" >/dev/null 2>&1 || true
  
  echo "Registrando el token de SonarQube en Jenkins como 'sonar-token'..."
  CRED_JSON=$(python3 -c "
import json
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'sonar-token',
    'secret': '$SONAR_TOKEN',
    'description': 'Token de SonarQube para análisis de código',
    '\$class': 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl'
  }
}))
")
  
  curl -s -u "$JENKINS_AUTH" -b "$JCOOKIES" -H "$JFIELD: $JCRUMB" --data-urlencode "json=$CRED_JSON" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "Jenkins Credential HTTP %{http_code}\n"
else
  echo "Jenkins no está levantado. Omitiendo el registro del token en Jenkins."
  echo "Ejecuta ./01_launch.sh y vuelve a ejecutar este script si la necesitas."
fi

echo
echo "SonarQube listo y configurado:"
echo "  URL:          $SONAR_URL"
echo "  Usuario:      admin"
echo "  Password:     $SONAR_ADMIN_PASSWORD"
echo "  Token:        $SONAR_TOKEN"
echo
