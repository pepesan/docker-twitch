#!/usr/bin/env bash
# Script 11: Genera certificados mTLS, instala Docker in LXC y expone la API de forma segura (puerto 2376).
set -euo pipefail

NODE_NAME="jenkins-external-docker"
FIXED_IP="10.207.154.80"
CERT_DIR="./config/certs"

echo "==> Generando certificados mTLS en el host..."
mkdir -p "$CERT_DIR"

# 1. Generar Autoridad de Certificación (CA) autofirmada de forma no interactiva
openssl genrsa -out "$CERT_DIR/ca-key.pem" 4096
openssl req -new -x509 -days 365 -key "$CERT_DIR/ca-key.pem" -sha256 -subj "/CN=Jenkins-Docker-CA" -out "$CERT_DIR/ca.pem"

# 2. Generar clave y certificado para el servidor Docker (LXC) con IP fija y localhost en SAN
openssl genrsa -out "$CERT_DIR/server-key.pem" 4096
openssl req -subj "/CN=$FIXED_IP" -sha256 -new -key "$CERT_DIR/server-key.pem" -out "$CERT_DIR/server.csr"

echo "subjectAltName = DNS:localhost,IP:$FIXED_IP,IP:127.0.0.1" > "$CERT_DIR/extfile.cnf"
echo "extendedKeyUsage = serverAuth" >> "$CERT_DIR/extfile.cnf"

openssl x509 -req -days 365 -sha256 -in "$CERT_DIR/server.csr" -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" \
  -CAcreateserial -out "$CERT_DIR/server-cert.pem" -extfile "$CERT_DIR/extfile.cnf"

# 3. Generar clave y certificado para el cliente (Jenkins Controller)
openssl genrsa -out "$CERT_DIR/key.pem" 4096
openssl req -subj "/CN=jenkins-controller" -new -key "$CERT_DIR/key.pem" -out "$CERT_DIR/client.csr"

echo "extendedKeyUsage = clientAuth" > "$CERT_DIR/extfile-client.cnf"

openssl x509 -req -days 365 -sha256 -in "$CERT_DIR/client.csr" -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" \
  -CAcreateserial -out "$CERT_DIR/cert.pem" -extfile "$CERT_DIR/extfile-client.cnf"

# Limpieza de archivos de firma temporales en el host
rm -f "$CERT_DIR/server.csr" "$CERT_DIR/client.csr" "$CERT_DIR/extfile.cnf" "$CERT_DIR/extfile-client.cnf" "$CERT_DIR/ca.srl"
chmod 0600 "$CERT_DIR"/*-key.pem "$CERT_DIR"/key.pem
echo "    [OK] Certificados generados en '$CERT_DIR'."

echo "==> Iniciando instalación de Docker dentro del contenedor LXC..."
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

# Subir los certificados del servidor al LXC de forma segura (usando redirección de stdin para evitar limitaciones de snap de LXD)
echo "==> Transfiriendo certificados del servidor al contenedor LXC..."
lxc exec "$NODE_NAME" -- mkdir -p /etc/docker
cat "$CERT_DIR/ca.pem" | lxc exec "$NODE_NAME" -- bash -c "cat > /etc/docker/ca.pem"
cat "$CERT_DIR/server-cert.pem" | lxc exec "$NODE_NAME" -- bash -c "cat > /etc/docker/server-cert.pem"
cat "$CERT_DIR/server-key.pem" | lxc exec "$NODE_NAME" -- bash -c "cat > /etc/docker/server-key.pem"

# Configurar el demonio de Docker en LXC para forzar TLS en el puerto 2376
echo "==> Configurando TLS y exponiendo API en tcp://0.0.0.0:2376..."
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

# Evitar conflictos de sockets en el inicio de systemd
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf <<'INI'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
INI

systemctl daemon-reload
systemctl restart docker.service containerd.service
systemctl enable --now docker.service containerd.service
echo "    [OK] Docker expuesto con mTLS seguro."
EOF

echo "==> [ÉXITO] Entorno Docker externo securizado con mTLS en tcp://$FIXED_IP:2376"
