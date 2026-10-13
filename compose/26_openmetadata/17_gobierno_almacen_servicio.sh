#!/usr/bin/env bash
# Fase 7 de gobierno del dato: SEGUNDO SERVICIO (ALMACÉN DE DATOS).
# La vista de plataforma/servicio de OpenMetadata solo dibuja flechas entre
# servicios distintos. Este script prepara un almacén de datos (esquema
# dwh_sakila en el mismo MySQL), crea el usuario del ETL y lo registra como
# segundo servicio (mysql_dwh). Las tablas y el linaje los crea después
# ./22_gobierno_linaje_etl.sh con un ETL real en Airflow.
# Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

echo "Fase 7: almacén de datos como segundo servicio"
echo "  preparando dwh_sakila y el usuario etl_user en MySQL..."
docker exec -i openmetadata_mysql mysql -u root -ppassword 2> >(grep -v 'Using a password' >&2) <<'SQL'
CREATE DATABASE IF NOT EXISTS dwh_sakila;
CREATE USER IF NOT EXISTS 'etl_user'@'%' IDENTIFIED BY 'etl_pass';
GRANT SELECT ON sakila.* TO 'etl_user'@'%';
GRANT ALL PRIVILEGES ON dwh_sakila.* TO 'etl_user'@'%';
GRANT SELECT, SHOW VIEW ON dwh_sakila.* TO 'openmetadata_user'@'%';
FLUSH PRIVILEGES;
SQL

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call

om_lib.login()
print("  registrando servicio mysql_dwh en OpenMetadata...")
svc = call("PUT", "/services/databaseServices", {
    "name": "mysql_dwh", "serviceType": "Mysql", "description": "Almacén de datos de Sakila",
    "connection": {"config": {"type": "Mysql", "username": "openmetadata_user",
        "authType": {"password": "openmetadata_password"},
        "hostPort": "mysql:3306", "databaseSchema": "dwh_sakila"}}})
pipe = call("PUT", "/services/ingestionPipelines", {
    "name": "mysql_dwh_metadata", "pipelineType": "metadata",
    "service": {"id": svc["id"], "type": "databaseService"},
    "sourceConfig": {"config": {"type": "DatabaseMetadata"}},
    "airflowConfig": {"scheduleInterval": "0 * * * *"}})
call("POST", f"/services/ingestionPipelines/deploy/{pipe['id']}")
print("Listo. Siguiente: ./22_gobierno_linaje_etl.sh (ETL real y linaje).")
PY
