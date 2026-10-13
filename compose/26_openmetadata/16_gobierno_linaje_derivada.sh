#!/usr/bin/env bash
# Fase 6 de gobierno del dato: LINAJE DE UNA TABLA DERIVADA (tipo ETL).
# Crea sakila.resumen_ventas_cliente a partir de customer, rental y payment,
# la ingesta en OpenMetadata y registra su linaje (tabla y columna) por API.
# Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

echo "Fase 6: linaje de una tabla derivada"
echo "  creando sakila.resumen_ventas_cliente en MySQL..."
docker exec -i openmetadata_mysql mysql -u root -ppassword 2> >(grep -v 'Using a password' >&2) <<'SQL'
DROP TABLE IF EXISTS sakila.resumen_ventas_cliente;
CREATE TABLE sakila.resumen_ventas_cliente AS
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS nombre,
       c.email,
       COUNT(DISTINCT r.rental_id)            AS num_alquileres,
       SUM(p.amount)                          AS total_pagado
FROM sakila.customer c
JOIN sakila.rental  r ON r.customer_id = c.customer_id
JOIN sakila.payment p ON p.rental_id   = r.rental_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;
SQL

PYTHONPATH=. python3 - <<'PY'
import sys, time
import om_lib
from om_lib import call, tag, glossary_tag, DB

om_lib.login()
TARGET = "resumen_ventas_cliente"

print("  reingestando metadatos para que OpenMetadata vea la tabla...")
pipe = call("GET", "/services/ingestionPipelines/name/mysql_sakila.mysql_sakila_metadata")
for _ in range(20):
    try:
        call("POST", f"/services/ingestionPipelines/trigger/{pipe['id']}")
        break
    except SystemExit:
        time.sleep(10)
else:
    sys.exit("No se pudo lanzar la ingestión; lánzala desde la UI y repite.")

for _ in range(30):
    if call("GET", f"/tables/name/{DB}.{TARGET}", ok_missing=True):
        break
    time.sleep(10)
else:
    sys.exit(f"La tabla {TARGET} no aparece en OpenMetadata todavía; repite en un minuto.")

ids = {n: call("GET", f"/tables/name/{DB}.{n}")["id"] for n in ("customer", "rental", "payment", TARGET)}
fq = lambda t, c: f"{DB}.{t}.{c}"

# origen -> [(columna origen, columna destino)]
EDGES = {
    "customer": [(["customer_id"], "customer_id"), (["first_name", "last_name"], "nombre"), (["email"], "email")],
    "rental": [(["rental_id"], "num_alquileres")],
    "payment": [(["amount"], "total_pagado")],
}
print("  registrando linaje...")
for src, cols in EDGES.items():
    call("PUT", "/lineage", {"edge": {
        "fromEntity": {"id": ids[src], "type": "table"},
        "toEntity": {"id": ids[TARGET], "type": "table"},
        "lineageDetails": {
            "description": "Resumen de ventas por cliente (carga SQL)",
            "columnsLineage": [
                {"fromColumns": [fq(src, c) for c in fcols], "toColumn": fq(TARGET, tcol)}
                for fcols, tcol in cols],
        }}})
    print(f"    {src} -> {TARGET}")

print("  aplicando gobierno a la tabla derivada...")
t = call("GET", f"/tables/name/{DB}.{TARGET}?fields=columns,tags,owners,domains")
team = call("GET", "/teams/name/EquipoComercial")
domain = call("GET", "/domains/name/Comercial")
ops = []
if not t.get("description"):
    ops.append({"op": "add", "path": "/description",
                "value": "Resumen de alquileres y pagos por cliente, derivado de customer, rental y payment."})
have = {x["tagFQN"] for x in t.get("tags", [])}
for wanted in (tag("Tier.Tier2"), glossary_tag("Cliente")):
    if wanted["tagFQN"] not in have:
        ops.append({"op": "add", "path": "/tags/-", "value": wanted})
if not t.get("owners"):
    ops.append({"op": "add", "path": "/owners", "value": [{"id": team["id"], "type": "team"}]})
if not t.get("domains"):
    ops.append({"op": "add", "path": "/domains", "value": [{"id": domain["id"], "type": "domain"}]})
for i, col in enumerate(t["columns"]):
    if col["name"] in ("nombre", "email") and "PII.Sensitive" not in {x["tagFQN"] for x in col.get("tags", [])}:
        ops.append({"op": "add", "path": f"/columns/{i}/tags/-", "value": tag("PII.Sensitive")})
if ops:
    call("PATCH", f"/tables/{t['id']}", ops, ctype="application/json-patch+json")
print("Listo. Explorar -> mysql_sakila -> sakila -> resumen_ventas_cliente -> pestaña Linaje.")
PY
