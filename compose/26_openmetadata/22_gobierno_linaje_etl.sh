#!/usr/bin/env bash
# Fase 8 de gobierno del dato: ETL REAL Y LINAJE DE PIPELINE.
# Despliega el DAG dags/etl_sakila_dwh.py en Airflow, lo ejecuta (carga
# dwh_sakila.dim_cliente y dwh_sakila.fact_pagos desde sakila), registra Airflow
# como servicio de pipelines en OpenMetadata y enlaza el linaje de las tablas
# con la pipeline que las carga. Requiere ./08_load_sakila.sh y
# ./17_gobierno_almacen_servicio.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

AIRFLOW_URL=${AIRFLOW_URL:-http://localhost:8080}
export AIRFLOW_URL
export AIRFLOW_ADMIN_USER=${AIRFLOW_ADMIN_USER:-admin}
export AIRFLOW_ADMIN_PASSWORD=${AIRFLOW_ADMIN_PASSWORD:-admin}

echo "Fase 8: ETL real y linaje de pipeline"
echo "  copiando el DAG al contenedor de Airflow..."
docker cp dags/etl_sakila_dwh.py openmetadata_ingestion:/opt/airflow/dags/etl_sakila_dwh.py

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - <<'PY'
import json, os, sys, time, urllib.error, urllib.request
import om_lib
from om_lib import call, tag, glossary_tag, DB

AF = os.environ["AIRFLOW_URL"]
DWH = "mysql_dwh.default.dwh_sakila"
PIPELINE = "airflow_etl.etl_sakila_dwh"


def af(method, path, body=None, token=None):
    r = urllib.request.Request(AF + path, method=method)
    if token:
        r.add_header("Authorization", "Bearer " + token)
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, data, timeout=30) as x:
            return json.loads(x.read() or b"{}")
    except urllib.error.HTTPError as e:
        return {"_error": e.code}


def trigger(pipeline_id):
    for _ in range(20):
        try:
            call("POST", f"/services/ingestionPipelines/trigger/{pipeline_id}")
            return
        except SystemExit:
            time.sleep(10)
    sys.exit("No se pudo lanzar una pipeline de ingestión; lánzala desde la UI y repite.")


def wait(cond, what, tries=30, pause=10):
    for _ in range(tries):
        v = cond()
        if v:
            return v
        time.sleep(pause)
    sys.exit(f"Tiempo agotado esperando: {what}")


om_lib.login()

# --- 1. Ejecutar el DAG en Airflow -------------------------------------------
print("  ejecutando el DAG etl_sakila_dwh en Airflow...")
tok = af("POST", "/auth/token", {"username": os.environ["AIRFLOW_ADMIN_USER"],
                                  "password": os.environ["AIRFLOW_ADMIN_PASSWORD"]})["access_token"]
# Airflow busca DAG nuevos cada refresh_interval (30 s en este compose; 300 s por defecto)
wait(lambda: "_error" not in af("GET", "/api/v2/dags/etl_sakila_dwh", token=tok), "que Airflow cargue el DAG", 72, 5)
af("PATCH", "/api/v2/dags/etl_sakila_dwh", {"is_paused": False}, tok)
run = af("POST", "/api/v2/dags/etl_sakila_dwh/dagRuns", {"logical_date": None}, tok)
rid = run["dag_run_id"]


def run_state():
    s = af("GET", f"/api/v2/dags/etl_sakila_dwh/dagRuns/{rid}", token=tok).get("state")
    return s if s in ("success", "failed") else None


state = wait(run_state, "que termine la ejecución del DAG", 40, 5)
if state != "success":
    sys.exit("La ejecución del DAG ha fallado; revisa el log en Airflow.")
print(f"  DAG ejecutado: {state}")

# --- 2. Ingestar el almacén y Airflow en OpenMetadata ------------------------
print("  ingestando mysql_dwh en OpenMetadata...")
dwh_pipe = call("GET", "/services/ingestionPipelines/name/mysql_dwh.mysql_dwh_metadata")
trigger(dwh_pipe["id"])
wait(lambda: all(call("GET", f"/tables/name/{DWH}.{t}", ok_missing=True) for t in ("dim_cliente", "fact_pagos")),
     "que aparezcan las tablas del almacén")

print("  registrando Airflow como servicio de pipelines...")
svc = call("PUT", "/services/pipelineServices", {
    "name": "airflow_etl", "serviceType": "Airflow", "description": "Airflow del laboratorio",
    "connection": {"config": {"type": "Airflow", "hostPort": AF, "numberOfStatus": 10,
        "connection": {"type": "Mysql", "username": "airflow_user", "authType": {"password": "airflow_pass"},
                       "hostPort": "mysql:3306", "databaseSchema": "airflow_db"}}}})
af_pipe = call("PUT", "/services/ingestionPipelines", {
    "name": "airflow_etl_metadata", "pipelineType": "metadata",
    "service": {"id": svc["id"], "type": "pipelineService"},
    "sourceConfig": {"config": {"type": "PipelineMetadata", "includeLineage": True}},
    "airflowConfig": {"scheduleInterval": "0 * * * *"}})
call("POST", f"/services/ingestionPipelines/deploy/{af_pipe['id']}")
trigger(af_pipe["id"])
pipeline = wait(lambda: call("GET", f"/pipelines/name/{PIPELINE}", ok_missing=True), "que aparezca la pipeline en OpenMetadata")

# --- 3. Linaje de las tablas a través de la pipeline -------------------------
EDGES = [
    ("customer", "dim_cliente", [(["customer_id"], "customer_id"), (["first_name", "last_name"], "nombre"),
                                  (["email"], "email"), (["active"], "active")]),
    ("payment", "fact_pagos", [(["payment_id"], "payment_id"), (["customer_id"], "customer_id"),
                                (["amount"], "amount"), (["payment_date"], "payment_date")]),
]


def pipeline_edge(dst):
    r = call("GET", f"/lineage/table/name/{DWH}.{dst}?upstreamDepth=1&downstreamDepth=0")
    for e in r.get("upstreamEdges", []):
        if ((e.get("lineageDetails") or {}).get("pipeline") or {}).get("id") == pipeline["id"]:
            return True
    return False


print("  esperando el linaje que deduce OpenMetadata de los inlets/outlets del DAG...")
auto = False
for _ in range(12):
    if all(pipeline_edge(d) for _, d, _ in EDGES):
        auto = True
        break
    time.sleep(10)

if auto:
    print("  linaje deducido automáticamente de la pipeline")
else:
    print("  OpenMetadata no lo ha deducido; registrando las aristas con referencia a la pipeline...")
    for s, d, cols in EDGES:
        call("PUT", "/lineage", {"edge": {
            "fromEntity": {"id": call("GET", f"/tables/name/{DB}.{s}")["id"], "type": "table"},
            "toEntity": {"id": call("GET", f"/tables/name/{DWH}.{d}")["id"], "type": "table"},
            "lineageDetails": {
                "pipeline": {"id": pipeline["id"], "type": "pipeline"},
                "description": "Carga al almacén de datos (ETL en Airflow)",
                "columnsLineage": [{"fromColumns": [f"{DB}.{s}.{c}" for c in fc], "toColumn": f"{DWH}.{d}.{tc}"}
                                   for fc, tc in cols]}}})
        print(f"    mysql_sakila.{s} -> mysql_dwh.{d} (vía {PIPELINE})")

# --- 4. Gobierno del almacén de datos ----------------------------------------
print("  aplicando gobierno al almacén de datos...")
team = call("GET", "/teams/name/EquipoComercial")
domain = call("GET", "/domains/name/Comercial")
META = {
    "dim_cliente": ("Dimensión de clientes del almacén de datos.", "Tier.Tier2", "Cliente", ["nombre", "email"]),
    "fact_pagos": ("Hechos de pagos del almacén de datos.", "Tier.Tier1", "Pago", []),
}
for name, (desc, tier, term, pii) in META.items():
    t = call("GET", f"/tables/name/{DWH}.{name}?fields=columns,tags,owners,domains")
    ops = []
    if not t.get("description"):
        ops.append({"op": "add", "path": "/description", "value": desc})
    have = {x["tagFQN"] for x in t.get("tags", [])}
    for w in (tag(tier), glossary_tag(term)):
        if w["tagFQN"] not in have:
            ops.append({"op": "add", "path": "/tags/-", "value": w})
    if not t.get("owners"):
        ops.append({"op": "add", "path": "/owners", "value": [{"id": team["id"], "type": "team"}]})
    if not t.get("domains"):
        ops.append({"op": "add", "path": "/domains", "value": [{"id": domain["id"], "type": "domain"}]})
    for i, c in enumerate(t["columns"]):
        if c["name"] in pii and "PII.Sensitive" not in {x["tagFQN"] for x in c.get("tags", [])}:
            ops.append({"op": "add", "path": f"/columns/{i}/tags/-", "value": tag("PII.Sensitive")})
    if ops:
        call("PATCH", f"/tables/{t['id']}", ops, ctype="application/json-patch+json")

print("Listo. Linaje de dim_cliente o fact_pagos -> pipeline etl_sakila_dwh; vista Servicio: mysql_sakila -> mysql_dwh.")
PY
