#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
base=../53_monitoring
"$base/00_init.sh"
certs=certs
mkdir -p "$certs"
if [[ -s "$certs/ca.crt" && -s "$certs/server.crt" && -s "$certs/server.key" && -s "$certs/client.crt" && -s "$certs/client.key" ]]; then
  echo 'Certificados de laboratorio existentes: se conservan.'
  exit 0
fi
shopt -s nullglob
existing=(certs/*)
if ((${#existing[@]})); then
  echo 'El directorio certs/ está incompleto; elimina su contenido local y vuelve a ejecutar 00_init.sh.' >&2
  exit 1
fi
umask 077
openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 365 \
  -keyout "$certs/ca.key" -out "$certs/ca.crt" -subj '/CN=monitoring-local-ca' \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign'
openssl req -newkey rsa:3072 -nodes -keyout "$certs/server.key" \
  -out "$certs/server.csr" -subj '/CN=localhost'
printf 'subjectAltName=DNS:localhost,IP:127.0.0.1\nbasicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n' > "$certs/server.ext"
openssl x509 -req -in "$certs/server.csr" -CA "$certs/ca.crt" -CAkey "$certs/ca.key" \
  -CAcreateserial -out "$certs/server.crt" -days 365 -sha256 -extfile "$certs/server.ext"
openssl req -newkey rsa:3072 -nodes -keyout "$certs/client.key" \
  -out "$certs/client.csr" -subj '/CN=monitoring-local-client'
printf 'basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=clientAuth\n' > "$certs/client.ext"
openssl x509 -req -in "$certs/client.csr" -CA "$certs/ca.crt" -CAkey "$certs/ca.key" \
  -CAserial "$certs/ca.srl" -out "$certs/client.crt" -days 365 -sha256 -extfile "$certs/client.ext"
echo 'Certificados de laboratorio creados en certs/ (ignorados por Git).'
