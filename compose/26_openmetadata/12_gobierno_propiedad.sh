#!/usr/bin/env bash
# Fase 4 de gobierno del dato: PROPIEDAD Y DOMINIO.
# Crea el equipo "Equipo Comercial" y el dominio "Comercial", y los asigna
# como propietario y dominio de todas las tablas y vistas de Sakila.
# Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call, tag, glossary_tag, patch_table, tag_ops, CATALOG

om_lib.login()

print("Fase 4: propiedad y dominio")
admin = call("GET", "/users/name/admin")
team = call("PUT", "/teams", {
    "name": "EquipoComercial", "displayName": "Equipo Comercial", "teamType": "Group",
    "description": "Responsable de los datos de clientes, alquileres y pagos.",
    "users": [admin["id"]]})
domain = call("PUT", "/domains", {
    "name": "Comercial", "displayName": "Comercial", "domainType": "Aggregate",
    "description": "Datos de la operación comercial: clientes, catálogo, alquileres y pagos."})

def ops(t):
    out = []
    if not t.get("owners"):
        out.append({"op": "add", "path": "/owners", "value": [{"id": team["id"], "type": "team"}]})
    if not t.get("domains"):
        out.append({"op": "add", "path": "/domains", "value": [{"id": domain["id"], "type": "domain"}]})
    return out

for table in CATALOG:
    patch_table(table, ops)
PY
