#!/usr/bin/env bash
# Crea (o actualiza) el servicio MySQL en OpenMetadata, su pipeline de ingestión
# de metadatos, la despliega en Airflow y la lanza. Es idempotente.
set -euo pipefail

API=${OPENMETADATA_API:-http://localhost:8585/api/v1}
ADMIN_EMAIL=${OPENMETADATA_ADMIN_EMAIL:-admin@open-metadata.org}
ADMIN_PASSWORD=${OPENMETADATA_ADMIN_PASSWORD:-admin}
SERVICE=mysql_openmetadata
PIPELINE=${SERVICE}_metadata

json() { python3 -c "import sys,json;print(json.load(sys.stdin)$1)"; }

TOKEN=$(curl -sf -X POST "$API/users/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$(printf '%s' "$ADMIN_PASSWORD" | base64)\"}" | json '["accessToken"]')
AUTH=(-H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json')

echo "Creando servicio $SERVICE..."
SERVICE_ID=$(curl -sf -X PUT "$API/services/databaseServices" "${AUTH[@]}" -d '{
  "name": "'$SERVICE'", "serviceType": "Mysql", "description": "MySQL del compose",
  "connection": {"config": {"type": "Mysql", "username": "openmetadata_user",
    "authType": {"password": "openmetadata_password"},
    "hostPort": "mysql:3306", "databaseSchema": "openmetadata_db"}}}' | json '["id"]')

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
for i in $(seq 1 20); do
  if curl -sf -X POST "$API/services/ingestionPipelines/trigger/$PIPELINE_ID" "${AUTH[@]}" >/dev/null; then
    echo "Ingestión lanzada. En unos segundos: Explorar -> Bases de datos -> $SERVICE"
    exit 0
  fi
  sleep 10
done
echo "No se pudo lanzar la ingestión; lánzala desde la UI (Servicios -> $SERVICE -> Ingestas)." >&2
exit 1
