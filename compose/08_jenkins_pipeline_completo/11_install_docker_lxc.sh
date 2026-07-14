#!/usr/bin/env bash
# Script 11: prepara Docker en LXC y expone su API con mTLS en 2376.
# Es idempotente: reutiliza certificados válidos y recarga Jenkins para
# que la credencial JCasC nunca conserve una CA anterior.
set -euo pipefail

cd "$(dirname "$0")"

NODE_NAME="jenkins-external-docker"
FIXED_IP="10.207.154.80"
CERT_DIR="./config/certs"
SSH_KEY_FILE="./config/ssh/id_ed25519"

if [ ! -f "$SSH_KEY_FILE" ]; then
  echo "==> Generando clave SSH para Jenkins..."
  mkdir -p "./config/ssh"
  ssh-keygen -t ed25519 -N "" -C "jenkins-agent" -f "$SSH_KEY_FILE"
fi

certificates_are_valid() {
  local required=(ca-key.pem ca.pem cert.pem key.pem server-cert.pem server-key.pem)
  local file

  for file in "${required[@]}"; do
    [ -s "$CERT_DIR/$file" ] || return 1
  done

  openssl verify -CAfile "$CERT_DIR/ca.pem" "$CERT_DIR/cert.pem" >/dev/null 2>&1 || return 1
  openssl verify -CAfile "$CERT_DIR/ca.pem" "$CERT_DIR/server-cert.pem" >/dev/null 2>&1 || return 1
  openssl x509 -checkend 86400 -noout -in "$CERT_DIR/cert.pem" >/dev/null 2>&1 || return 1
  openssl x509 -checkend 86400 -noout -in "$CERT_DIR/server-cert.pem" >/dev/null 2>&1 || return 1
  openssl x509 -in "$CERT_DIR/server-cert.pem" -noout -ext subjectAltName 2>/dev/null \
    | grep -q "IP Address:$FIXED_IP" || return 1
}

generate_certificates() {
  echo "==> Generando certificados mTLS para Docker externo..."
  mkdir -p "$CERT_DIR"
  rm -f "$CERT_DIR"/{ca-key.pem,ca.pem,cert.pem,key.pem,server-cert.pem,server-key.pem}
  rm -f "$CERT_DIR"/{server.csr,client.csr,extfile.cnf,extfile-client.cnf,ca.srl}

  openssl genrsa -out "$CERT_DIR/ca-key.pem" 4096
  openssl req -new -x509 -days 365 -key "$CERT_DIR/ca-key.pem" -sha256 \
    -subj "/CN=Jenkins-Docker-CA" -out "$CERT_DIR/ca.pem"

  openssl genrsa -out "$CERT_DIR/server-key.pem" 4096
  openssl req -subj "/CN=$FIXED_IP" -sha256 -new \
    -key "$CERT_DIR/server-key.pem" -out "$CERT_DIR/server.csr"
  printf '%s\n' "subjectAltName = DNS:localhost,IP:$FIXED_IP,IP:127.0.0.1" \
    "extendedKeyUsage = serverAuth" > "$CERT_DIR/extfile.cnf"
  openssl x509 -req -days 365 -sha256 -in "$CERT_DIR/server.csr" \
    -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -CAcreateserial \
    -out "$CERT_DIR/server-cert.pem" -extfile "$CERT_DIR/extfile.cnf"

  openssl genrsa -out "$CERT_DIR/key.pem" 4096
  openssl req -subj "/CN=jenkins-controller" -new \
    -key "$CERT_DIR/key.pem" -out "$CERT_DIR/client.csr"
  printf '%s\n' "extendedKeyUsage = clientAuth" > "$CERT_DIR/extfile-client.cnf"
  openssl x509 -req -days 365 -sha256 -in "$CERT_DIR/client.csr" \
    -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -CAcreateserial \
    -out "$CERT_DIR/cert.pem" -extfile "$CERT_DIR/extfile-client.cnf"

  rm -f "$CERT_DIR"/{server.csr,client.csr,extfile.cnf,extfile-client.cnf,ca.srl}
  chmod 0600 "$CERT_DIR/ca-key.pem" "$CERT_DIR/server-key.pem" "$CERT_DIR/key.pem"
  echo "    [OK] Certificados generados en '$CERT_DIR'."
}

if ! lxc info "$NODE_NAME" >/dev/null 2>&1; then
  echo "ERROR: El contenedor LXC '$NODE_NAME' no existe. Ejecuta primero ./10_create_lxc_docker_node.sh." >&2
  exit 1
fi

if certificates_are_valid; then
  echo "==> Reutilizando certificados mTLS existentes y válidos."
else
  generate_certificates
fi

if lxc exec "$NODE_NAME" -- sh -c 'command -v docker >/dev/null 2>&1'; then
  echo "==> Docker ya está instalado dentro del LXC."
else
  echo "==> Instalando Docker dentro del contenedor LXC..."
  lxc exec "$NODE_NAME" -- bash -s <<'EOF'
set -euo pipefail
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
EOF
fi

# Instalar dependencias de Python para soporte de módulos Ansible de Docker
if lxc exec "$NODE_NAME" -- sh -c 'dpkg -s python3-docker >/dev/null 2>&1'; then
  echo "==> python3-docker ya está instalado dentro del LXC."
else
  echo "==> Instalando python3-docker dentro del LXC..."
  lxc exec "$NODE_NAME" -- apt-get update -qq
  lxc exec "$NODE_NAME" -- apt-get install -y -qq python3-docker
fi

echo "==> Transfiriendo certificados del servidor al contenedor LXC..."
lxc exec "$NODE_NAME" -- mkdir -p /etc/docker
lxc exec "$NODE_NAME" -- bash -c 'cat > /etc/docker/ca.pem' < "$CERT_DIR/ca.pem"
lxc exec "$NODE_NAME" -- bash -c 'cat > /etc/docker/server-cert.pem' < "$CERT_DIR/server-cert.pem"
lxc exec "$NODE_NAME" -- bash -c 'cat > /etc/docker/server-key.pem' < "$CERT_DIR/server-key.pem"
lxc exec "$NODE_NAME" -- chmod 0600 /etc/docker/server-key.pem

echo "==> Configurando clave SSH de Jenkins en el contenedor LXC..."
lxc exec "$NODE_NAME" -- mkdir -p /root/.ssh
lxc exec "$NODE_NAME" -- chmod 700 /root/.ssh
lxc exec "$NODE_NAME" -- bash -c 'cat >> /root/.ssh/authorized_keys' < "${SSH_KEY_FILE}.pub"
lxc exec "$NODE_NAME" -- chmod 600 /root/.ssh/authorized_keys
lxc exec "$NODE_NAME" -- bash -c 'sort -u -o /root/.ssh/authorized_keys /root/.ssh/authorized_keys'

echo "==> Configurando Docker con mTLS en tcp://0.0.0.0:2376..."
lxc exec "$NODE_NAME" -- bash -s <<'EOF'
set -euo pipefail
cat > /etc/docker/daemon.json <<'JSON'
{
  "hosts": [
    "unix:///var/run/docker.sock",
    "tcp://0.0.0.0:2376"
  ],
  "tls": true,
  "tlsverify": true,
  "tlscacert": "/etc/docker/ca.pem",
  "tlscert": "/etc/docker/server-cert.pem",
  "tlskey": "/etc/docker/server-key.pem"
}
JSON

mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf <<'INI'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
INI

systemctl daemon-reload
systemctl restart docker.service containerd.service
systemctl enable --now docker.service containerd.service
EOF

echo "==> Verificando la API Docker remota con los certificados de cliente..."
PING=$(curl -sf --cert "$CERT_DIR/cert.pem" --key "$CERT_DIR/key.pem" \
  --cacert "$CERT_DIR/ca.pem" "https://$FIXED_IP:2376/_ping")
if [ "$PING" != "OK" ]; then
  echo "ERROR: La API Docker externa no respondió correctamente." >&2
  exit 1
fi
echo "    [OK] API Docker externa accesible mediante mTLS."

# JCasC lee los PEM al arrancar y los guarda en la credencial
# docker-external-tls-creds. Reiniciar evita que Jenkins conserve una CA
# anterior si los certificados se acaban de crear o renovar.
if [ -n "$(docker ps --filter 'name=^jenkins_docker_pipeline$' --filter status=running -q 2>/dev/null)" ]; then
  echo "==> Reiniciando Jenkins para recargar docker-external-tls-creds..."
  docker compose -p jenkins_docker_pipeline restart jenkins_controller

  JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
  JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
  JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
  for attempt in $(seq 1 60); do
    CODE=$(curl -s -o /dev/null -w '%{http_code}' \
      -u "$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD" \
      "$JENKINS_URL/api/json" 2>/dev/null || true)
    if [ "$CODE" = "200" ]; then
      echo "    [OK] Jenkins listo con las credenciales TLS actualizadas."
      break
    fi
    if [ "$attempt" -eq 60 ]; then
      echo "ERROR: Jenkins no volvió a responder después de recargar los certificados." >&2
      exit 1
    fi
    sleep 2
  done
fi

echo "==> [ÉXITO] Docker externo listo en tcp://$FIXED_IP:2376"
