#!/usr/bin/env bash
# Uso 1: ACTIVOS SEGUIDOS Y MIS DATOS.
# El usuario admin sigue las tablas principales (widget "Activos seguidos" de
# la portada) y es propietario directo de los activos analíticos derivados
# (widget "Mis datos"). OpenMetadata no permite mezclar un equipo y usuarios
# como propietarios, así que en estos activos el propietario pasa del equipo
# al usuario. Requiere ./08_load_sakila.sh y ./16_gobierno_linaje_derivada.sh.
# Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call, DB

om_lib.login()
FOLLOW = ["customer", "rental", "payment", "film", "inventory",
          "resumen_ventas_cliente", "customer_list", "sales_by_store", "sales_by_film_category", "film_list"]
OWN = ["resumen_ventas_cliente", "customer_list", "sales_by_store", "sales_by_film_category", "film_list"]
admin = call("GET", "/users/name/admin")

print("Uso 1: activos seguidos y mis datos")
for name in FOLLOW:
    t = call("GET", f"/tables/name/{DB}.{name}?fields=owners,followers", ok_missing=True)
    if t is None:
        print(f"  {name}: no existe (¿falta ejecutar la fase 6?)")
        continue
    if admin["id"] not in {f["id"] for f in t.get("followers", [])}:
        call("PUT", f"/tables/{t['id']}/followers", admin["id"])
    msg = "seguida"
    if name in OWN and {o["id"] for o in t.get("owners", [])} != {admin["id"]}:
        call("PATCH", f"/tables/{t['id']}", [{"op": "add", "path": "/owners",
             "value": [{"id": admin["id"], "type": "user"}]}], ctype="application/json-patch+json")
        msg += " y propia"
    print(f"  {name}: {msg}")
PY
