#!/usr/bin/env bash
# Fase 2 de gobierno del dato: CLASIFICACIÓN.
# Marca los datos personales con PII.Sensitive (clientes, empleados, direcciones)
# o PII.NonSensitive (actores, personajes públicos) y asigna un Tier de
# criticidad a todas las tablas y vistas de Sakila.
# Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call, tag, glossary_tag, patch_table, tag_ops, CATALOG

om_lib.login()

PII = tag("PII.Sensitive")
NON_SENSITIVE = tag("PII.NonSensitive")
PII_COLUMNS = {
    "customer": ["first_name", "last_name", "email"],
    "address": ["address", "address2", "phone", "postal_code"],
    "staff": ["first_name", "last_name", "email", "username", "password", "picture"],
    "customer_list": ["name", "address", "zip code", "phone"],
    "staff_list": ["name", "address", "zip code", "phone"],
    "sales_by_store": ["manager"],
}
NON_SENSITIVE_COLUMNS = {
    "actor": ["first_name", "last_name"],
    "actor_info": ["first_name", "last_name"],
}

print("Fase 2: clasificación (PII y Tier)")
for table, (_, tier, _) in CATALOG.items():
    cols = {c: [PII] for c in PII_COLUMNS.get(table, [])}
    cols.update({c: [NON_SENSITIVE] for c in NON_SENSITIVE_COLUMNS.get(table, [])})
    patch_table(table, lambda t, tier=tier, cols=cols: tag_ops(t, [tag(tier)], cols))
PY
