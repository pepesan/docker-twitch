#!/usr/bin/env bash
# Descarga la base de datos de ejemplo Sakila (MySQL), la carga en el MySQL del
# compose y la registra en OpenMetadata (servicio mysql_sakila + pipeline de
# ingestión de metadatos). Es idempotente.
set -euo pipefail

URL=https://downloads.mysql.com/docs/sakila-db.tar.gz
API=${OPENMETADATA_API:-http://localhost:8585/api/v1}
ADMIN_EMAIL=${OPENMETADATA_ADMIN_EMAIL:-admin@open-metadata.org}
ADMIN_PASSWORD=${OPENMETADATA_ADMIN_PASSWORD:-admin}
SERVICE=mysql_sakila
PIPELINE=${SERVICE}_metadata

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Descargando Sakila..."
curl -sfL -o "$TMP/sakila-db.tar.gz" "$URL"
tar xzf "$TMP/sakila-db.tar.gz" -C "$TMP"

MYSQL=(docker exec -i openmetadata_mysql mysql -u root -ppassword)

echo "Cargando esquema y datos en MySQL..."
"${MYSQL[@]}" < "$TMP/sakila-db/sakila-schema.sql" 2> >(grep -v 'Using a password' >&2)
"${MYSQL[@]}" < "$TMP/sakila-db/sakila-data.sql" 2> >(grep -v 'Using a password' >&2)

echo "Dando permisos de lectura a openmetadata_user..."
"${MYSQL[@]}" -e "GRANT SELECT, SHOW VIEW ON sakila.* TO 'openmetadata_user'@'%'; FLUSH PRIVILEGES;" \
  2> >(grep -v 'Using a password' >&2)

echo "Filas en sakila.film: $("${MYSQL[@]}" -N -e 'SELECT COUNT(*) FROM sakila.film' 2>/dev/null)"

json() { python3 -c "import sys,json;print(json.load(sys.stdin)$1)"; }

TOKEN=$(curl -sf -X POST "$API/users/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$(printf '%s' "$ADMIN_PASSWORD" | base64)\"}" | json '["accessToken"]')
AUTH=(-H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json')

echo "Creando servicio $SERVICE en OpenMetadata..."
SERVICE_ID=$(curl -sf -X PUT "$API/services/databaseServices" "${AUTH[@]}" -d '{
  "name": "'$SERVICE'", "serviceType": "Mysql", "description": "Base de datos de ejemplo Sakila",
  "connection": {"config": {"type": "Mysql", "username": "openmetadata_user",
    "authType": {"password": "openmetadata_password"},
    "hostPort": "mysql:3306", "databaseSchema": "sakila"}}}' | json '["id"]')

echo "Creando pipeline $PIPELINE..."
PIPELINE_ID=$(curl -sf -X PUT "$API/services/ingestionPipelines" "${AUTH[@]}" -d '{
  "name": "'$PIPELINE'", "pipelineType": "metadata",
  "service": {"id": "'$SERVICE_ID'", "type": "databaseService"},
  "sourceConfig": {"config": {"type": "DatabaseMetadata"}},
  "airflowConfig": {"scheduleInterval": "0 * * * *"}}' | json '["id"]')

echo "Desplegando pipeline en Airflow..."
curl -sf -X POST "$API/services/ingestionPipelines/deploy/$PIPELINE_ID" "${AUTH[@]}" >/dev/null

# Airflow tarda unos segundos en registrar el DAG recién desplegado
echo "Lanzando ingestión..."
for _ in $(seq 1 20); do
  if curl -sf -X POST "$API/services/ingestionPipelines/trigger/$PIPELINE_ID" "${AUTH[@]}" >/dev/null; then
    echo "Ingestión lanzada. En unos segundos: Explorar -> Bases de datos -> $SERVICE"
    exit 0
  fi
  sleep 10
done
echo "No se pudo lanzar la ingestión; lánzala desde la UI (Servicios -> $SERVICE -> Ingestas)." >&2
exit 1
