#!/usr/bin/env bash
# Fase 5 de gobierno del dato: LINAJE AUTOMÁTICO DESDE LAS VISTAS.
# Crea una pipeline de ingestión de tipo "lineage" para mysql_sakila: lee el SQL
# de cada vista (customer_list, sales_by_store...) y deduce de qué tablas se
# alimenta. Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - <<'PY'
import sys, time
import om_lib
from om_lib import call, DB

om_lib.login()
print("Fase 5: linaje automático desde las vistas")

svc = call("GET", "/services/databaseServices/name/mysql_sakila")
pipe = call("PUT", "/services/ingestionPipelines", {
    "name": "mysql_sakila_lineage", "pipelineType": "lineage",
    "service": {"id": svc["id"], "type": "databaseService"},
    "sourceConfig": {"config": {"type": "DatabaseLineage", "queryLogDuration": 1, "resultLimit": 1000}},
    "airflowConfig": {"scheduleInterval": "0 * * * *"}})
call("POST", f"/services/ingestionPipelines/deploy/{pipe['id']}")
print("  pipeline de linaje desplegada")

for _ in range(20):
    try:
        call("POST", f"/services/ingestionPipelines/trigger/{pipe['id']}")
        break
    except SystemExit:
        time.sleep(10)
else:
    sys.exit("No se pudo lanzar la pipeline; lánzala desde la UI.")
print("  ingestión lanzada, esperando linaje (máx. 3 min)...")

VIEWS = ["customer_list", "staff_list", "film_list", "nicer_but_slower_film_list",
         "actor_info", "sales_by_store", "sales_by_film_category"]
for _ in range(18):
    time.sleep(10)
    found = {}
    for v in VIEWS:
        r = call("GET", f"/lineage/table/name/{DB}.{v}?upstreamDepth=1&downstreamDepth=0", ok_missing=True)
        found[v] = sorted(n["name"] for n in (r or {}).get("nodes", []) if n["name"] != v)
    if all(found.values()):
        break
for v, ups in found.items():
    print(f"  {v} <- {', '.join(ups) if ups else '(sin linaje)'}")
if not all(found.values()):
    sys.exit("Alguna vista no tiene linaje todavía; revisa el log de la pipeline en Airflow.")
PY
