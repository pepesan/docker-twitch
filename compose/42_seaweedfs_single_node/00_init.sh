#!/usr/bin/env bash
# Crea la carpeta de datos persistentes ./data y genera credenciales S3
# nuevas en s3-config/s3.json (a partir de la plantilla, no versionado —
# ver .gitignore). Ejecutar una vez antes del primer 01_launch_compose.sh
# y cada vez que se borre con 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p data

if [ -f s3-config/s3.json ]; then
    echo "s3-config/s3.json ya existe, no se regenera (borra el fichero si quieres credenciales nuevas)."
else
    access_key=$(openssl rand -hex 10)
    secret_key=$(openssl rand -hex 20)
    sed -e "s/__S3_ACCESS_KEY__/${access_key}/" \
        -e "s/__S3_SECRET_KEY__/${secret_key}/" \
        s3-config/s3.json.template > s3-config/s3.json
    echo "Credenciales S3 generadas en s3-config/s3.json:"
    echo "  accessKey: ${access_key}"
    echo "  secretKey: ${secret_key}"
fi
