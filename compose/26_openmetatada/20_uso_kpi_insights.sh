#!/usr/bin/env bash
# Uso 3: KPI Y TOTAL DE ACTIVOS.
# Crea dos KPI (cobertura de descripciones y de propietarios) y ejecuta la
# aplicación Data Insights, que alimenta los widgets KPI y "Total de activos"
# de la portada. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - <<'PY'
import sys, time
import om_lib
from om_lib import call, tag, DB

om_lib.login()

now = int(time.time() * 1000)
KPIS = [
    ("cobertura_descripciones", "Cobertura de descripciones",
     "Porcentaje de activos con descripción.", "percentage_of_data_asset_with_description_kpi"),
    ("cobertura_propietarios", "Cobertura de propietarios",
     "Porcentaje de activos con propietario.", "percentage_of_data_asset_with_owner_kpi"),
]

print("Uso 3: KPI y data insights")
for name, display, desc, chart in KPIS:
    call("PUT", "/kpi", {"name": name, "displayName": display, "description": desc, "dataInsightChart": chart,
        "startDate": now, "endDate": now + 90 * 86400000, "metricType": "PERCENTAGE", "targetValue": 100})
    print(f"  KPI: {display}")

def last_start():
    r = call("GET", "/apps/name/DataInsightsApplication/status?limit=1", ok_missing=True) or {}
    d = r.get("data", [])
    return (d[0].get("startTime") or 0, d[0].get("status")) if d else (0, None)

before, _ = last_start()
call("POST", "/apps/trigger/DataInsightsApplication", {})
print("  Data Insights lanzado, esperando (máx. 5 min)...")
for _ in range(30):
    time.sleep(10)
    start, status = last_start()
    if start > before and status in ("success", "failed"):
        print(f"  Data Insights terminado: {status}")
        break
else:
    sys.exit("Data Insights no ha terminado todavía; revisa Configuraciones -> Aplicaciones.")
PY
