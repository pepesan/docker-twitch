#!/usr/bin/env bash
# Fase 5 de gobierno del dato: CALIDAD.
# Crea casos de prueba de calidad sobre Sakila, una pipeline de tests por tabla
# en Airflow y la lanza. Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call, tag, glossary_tag, patch_table, tag_ops

om_lib.login()

import sys, time
from om_lib import DB

TESTS = [
    # (tabla, columna o None, definición, nombre, parámetros)
    ("customer", "email", "columnValuesToBeNotNull", "customer_email_no_nulo", []),
    ("customer", "email", "columnValuesToBeUnique", "customer_email_unico", []),
    ("payment", "amount", "columnValuesToBeBetween", "payment_amount_entre_0_y_100",
     [{"name": "minValue", "value": "0"}, {"name": "maxValue", "value": "100"}]),
    ("film", None, "tableRowCountToBeBetween", "film_filas_entre_500_y_2000",
     [{"name": "minValue", "value": "500"}, {"name": "maxValue", "value": "2000"}]),
    ("address", "postal_code", "columnValuesToBeNotNull", "address_postal_code_no_nulo", []),
    # Falla a propósito: address2 es NULL en casi todas las filas de Sakila
    ("address", "address2", "columnValuesToBeNotNull", "address_address2_no_nulo", []),
]

print("Fase 5: calidad del dato")
tables = []
for table, column, definition, name, params in TESTS:
    fqn = f"{DB}.{table}"
    if table not in tables:
        tables.append(table)
        if call("GET", f"/dataQuality/testSuites/name/{fqn}.testSuite", ok_missing=True) is None:
            call("POST", "/dataQuality/testSuites/basic", {"name": f"{fqn}.testSuite", "basicEntityReference": fqn})
    link = f"<#E::table::{fqn}" + (f"::columns::{column}>" if column else ">")
    call("PUT", "/dataQuality/testCases", {
        "name": name, "entityLink": link, "testDefinition": definition, "parameterValues": params})
    print(f"  test {name}")

print("Pipelines de calidad en Airflow...")
for table in tables:
    fqn = f"{DB}.{table}"
    suite = call("GET", f"/dataQuality/testSuites/name/{fqn}.testSuite")
    pipe = call("PUT", "/services/ingestionPipelines", {
        "name": f"{table}_calidad", "pipelineType": "TestSuite",
        "service": {"id": suite["id"], "type": "testSuite"},
        "sourceConfig": {"config": {"type": "TestSuite", "entityFullyQualifiedName": fqn}},
        "airflowConfig": {"scheduleInterval": "0 * * * *"}})
    call("POST", f"/services/ingestionPipelines/deploy/{pipe['id']}")
    for _ in range(20):
        try:
            call("POST", f"/services/ingestionPipelines/trigger/{pipe['id']}")
            print(f"  {table}: pipeline lanzada")
            break
        except SystemExit:
            time.sleep(10)
    else:
        print(f"  {table}: no se pudo lanzar; hazlo desde la UI", file=sys.stderr)
PY
