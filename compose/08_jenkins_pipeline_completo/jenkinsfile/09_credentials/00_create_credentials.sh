#!/bin/bash
# Da de alta en Jenkins las credenciales de demostración que usa este
# ejemplo: usuario/contraseña, texto secreto, clave SSH y fichero secreto.
# Ejecutar antes de 01_create.sh / 02_build.sh. Idempotente: si una
# credencial ya existe, no la vuelve a crear.
set -e
cd "$(dirname "$0")"

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

COOKIES=$(mktemp)
SSH_TMP=$(mktemp -d)
FILE_TMP=$(mktemp -d)
trap 'rm -f "$COOKIES"; rm -rf "$SSH_TMP" "$FILE_TMP"' EXIT

CRUMB_JSON=$(curl -sf -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")
FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumbRequestField'])")

exists() {
  local ID="$1"
  local CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" "$JENKINS_URL/credentials/store/system/domain/_/credential/$ID/api/json")
  [ "$CODE" = "200" ]
}

# 1) Usuario y contraseña
if exists "demo-user-pass"; then
  echo "La credencial 'demo-user-pass' ya existe."
else
  echo "Creando la credencial 'demo-user-pass' (usuario/contraseña)..."
  JSON=$(python3 -c "
import json
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'demo-user-pass',
    'username': 'demo-user',
    'password': 'demo-password',
    'description': 'Ejemplo: usuario y contraseña',
    '\$class': 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl'
  }
}))
")
  curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" --data-urlencode "json=$JSON" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
fi

# 2) Texto secreto
if exists "demo-secret-text"; then
  echo "La credencial 'demo-secret-text' ya existe."
else
  echo "Creando la credencial 'demo-secret-text' (texto secreto)..."
  JSON=$(python3 -c "
import json
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'demo-secret-text',
    'secret': 's3cr3t0-de-ejemplo',
    'description': 'Ejemplo: texto secreto',
    '\$class': 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl'
  }
}))
")
  curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" --data-urlencode "json=$JSON" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
fi

# 3) Clave SSH (generada al vuelo en cada ejecución; nunca se guarda en el repo)
if exists "demo-ssh-key"; then
  echo "La credencial 'demo-ssh-key' ya existe."
else
  echo "Creando la credencial 'demo-ssh-key' (clave SSH privada)..."
  ssh-keygen -t ed25519 -N "" -C "demo" -f "$SSH_TMP/demo_key" -q
  JSON=$(python3 -c "
import json
key = open('$SSH_TMP/demo_key').read()
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'demo-ssh-key',
    'username': 'demo',
    'privateKeySource': {
      'value': '0',
      'privateKey': key,
      'stapler-class': 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource'
    },
    'passphrase': '',
    'description': 'Ejemplo: clave SSH privada',
    '\$class': 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey'
  }
}))
")
  curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" --data-urlencode "json=$JSON" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
fi

# 4) Fichero secreto
if exists "demo-config-file"; then
  echo "La credencial 'demo-config-file' ya existe."
else
  echo "Creando la credencial 'demo-config-file' (fichero secreto)..."
  printf 'entorno=demo\nversion=1.0.0\n' > "$FILE_TMP/config-demo.properties"
  JSON=$(python3 -c "
import json
print(json.dumps({
  'credentials': {
    'scope': 'GLOBAL',
    'id': 'demo-config-file',
    'file': 'file0',
    'fileName': 'config-demo.properties',
    'description': 'Ejemplo: fichero secreto',
    '\$class': 'org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl'
  }
}))
")
  curl -s -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" \
    -F "json=$JSON" \
    -F "file0=@$FILE_TMP/config-demo.properties;filename=config-demo.properties" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" -o /dev/null -w "HTTP %{http_code}\n"
fi

echo "Credenciales de demostración listas. Ver: $JENKINS_URL/manage/credentials/store/system/domain/_/"
