#!/bin/bash
# Prepara los directorios de volúmenes antes de lanzar los contenedores
set -e
cd "$(dirname "$0")"
mkdir -p ./jenkins_home
chmod -R 777 ./jenkins_home 2>/dev/null || true
mkdir -p ./config/ssh

# Crear directorio de certificados y placeholders para evitar fallos de JCasC en el arranque limpio
mkdir -p ./config/certs
if [ ! -f ./config/certs/key.pem ]; then
  echo "==> Generando certificados temporales para evitar fallos de inicio de JCasC..."
  openssl genrsa -out ./config/certs/ca-key.pem 1024
  openssl req -new -x509 -days 1 -key ./config/certs/ca-key.pem -subj "/CN=Dummy-CA" -out ./config/certs/ca.pem
  openssl genrsa -out ./config/certs/key.pem 1024
  openssl req -new -key ./config/certs/key.pem -subj "/CN=Dummy-Client" -out ./config/certs/client.csr
  openssl x509 -req -days 1 -in ./config/certs/client.csr -CA ./config/certs/ca.pem -CAkey ./config/certs/ca-key.pem -CAcreateserial -out ./config/certs/cert.pem
  rm -f ./config/certs/client.csr ./config/certs/ca.srl
  echo "    [OK] Certificados temporales listos."
fi

echo "Listo. Ahora ejecuta ./01_launch.sh para construir y arrancar el Jenkins controller."
