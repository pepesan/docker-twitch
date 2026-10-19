#!/usr/bin/env bash
# Verifica por API que cada fase del laboratorio dejó lo esperado. Solo lectura.
# Uso: ./91_e2e_verificar.sh [fase ...]
#   fases: 07 08 doc 13 15 16 17 22 uso   (sin argumentos: todas)
# Código de salida: 0 si todo pasa, 1 si algo falla.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - "$@" <<'PY'
import subprocess, sys, time
import om_lib
from om_lib import call

SK = "mysql_sakila.default.sakila"
DWH = "mysql_dwh.default.dwh_sakila"
RESULTS = []


def eventually(fn, tries=1, pause=10):
    """Repite fn hasta que devuelva (True, detalle) o se agoten los intentos."""
    res = (False, "sin ejecutar")
    for i in range(tries):
        try:
            res = fn()
        except SystemExit as e:
            res = (False, str(e)[:120])
        if res[0]:
            break
        if i < tries - 1:
            time.sleep(pause)
    return res


def check(phase, name, fn, tries=1, pause=10):
    ok, detail = eventually(fn, tries, pause)
    RESULTS.append((phase, name, ok, detail))
    print(f"  [{'PASS' if ok else 'FAIL'}] {phase:>3} {name}: {detail}", flush=True)


def tables(schema_fqn):
    return call("GET", f"/tables?databaseSchema={schema_fqn}&limit=100&fields=tags,owners,domains,columns")["data"]


def upstream(fqn, depth=1):
    r = call("GET", f"/lineage/table/name/{fqn}?upstreamDepth={depth}&downstreamDepth=0", ok_missing=True) or {}
    return r


def has_tag(t, prefix):
    return any(x["tagFQN"].startswith(prefix) for x in t.get("tags", []))


def mysql_count(sql):
    out = subprocess.run(["docker", "exec", "openmetadata_mysql", "mysql", "-u", "root", "-ppassword", "-N", "-e", sql],
                         capture_output=True, text=True)
    return int(out.stdout.strip().split()[-1])


# login sin exigir mysql_sakila (la fase 07 se verifica antes de cargar Sakila)
import base64
om_lib._token = om_lib.login_token(base64.b64encode(om_lib.PASSWORD.encode()).decode())

wanted = set(sys.argv[1:])
run = lambda p: not wanted or p in wanted


if run("07"):
    print("Fase 07: servicio MySQL y tabla clientes")
    check("07", "servicio mysql_openmetadata", lambda: (
        call("GET", "/services/databaseServices/name/mysql_openmetadata", ok_missing=True) is not None, ""), 6)
    check("07", "tabla clientes catalogada", lambda: (
        call("GET", "/tables/name/mysql_openmetadata.default.openmetadata_db.clientes", ok_missing=True) is not None, ""), 18)

if run("08"):
    print("Fase 08: Sakila cargada y catalogada")
    # resumen_ventas_cliente (fase 16) comparte esquema pero no es de Sakila
    sakila_tables = lambda: [t for t in tables(SK) if t["name"] != "resumen_ventas_cliente"]
    check("08", "23 tablas y vistas de Sakila en OpenMetadata", lambda: (
        len(sakila_tables()) == 23, f"{len(sakila_tables())} encontradas"), 18)
    check("08", "1000 filas en sakila.film", lambda: (mysql_count("SELECT COUNT(*) FROM sakila.film") == 1000, ""))

if run("doc"):
    print("Fases 09-12: documentación, clasificación, glosario, propiedad")
    ts = tables(SK)
    n = len(ts)
    check("09", "descripción en todas", lambda: (sum(bool(t.get("description")) for t in ts) == n, f"{sum(bool(t.get('description')) for t in ts)}/{n}"))
    check("10", "Tier en todas", lambda: (sum(has_tag(t, "Tier.") for t in ts) == n, f"{sum(has_tag(t, 'Tier.') for t in ts)}/{n}"))
    cust = call("GET", f"/tables/name/{SK}.customer?fields=columns,tags")
    check("10", "PII.Sensitive en customer.email", lambda: (
        any(c["name"] == "email" and any(x["tagFQN"] == "PII.Sensitive" for x in c.get("tags", [])) for c in cust["columns"]), ""))
    check("11", "término de glosario en todas", lambda: (sum(has_tag(t, "GlosarioSakila.") for t in ts) == n, f"{sum(has_tag(t, 'GlosarioSakila.') for t in ts)}/{n}"))
    check("12", "propietario y dominio en todas", lambda: (
        sum(bool(t.get("owners")) and bool(t.get("domains")) for t in ts) == n,
        f"{sum(bool(t.get('owners')) and bool(t.get('domains')) for t in ts)}/{n}"))

if run("13"):
    print("Fase 13: calidad del dato")
    def quality():
        cs = call("GET", "/dataQuality/testCases?limit=100&fields=testCaseResult")["data"]
        cs = [c for c in cs if c["fullyQualifiedName"].startswith("mysql_sakila")]
        st = sorted(c.get("testCaseResult", {}).get("testCaseStatus", "sin ejecutar") for c in cs)
        return (len(cs) == 6 and st.count("Success") == 5 and st.count("Failed") == 1, f"{len(cs)} casos, estados: {st}")
    check("13", "6 casos: 5 Success y 1 Failed", quality, 24)

if run("15"):
    print("Fase 15: linaje desde las vistas")
    for v in ("customer_list", "staff_list", "film_list", "nicer_but_slower_film_list", "actor_info",
              "sales_by_store", "sales_by_film_category"):
        check("15", f"{v} con origen", lambda v=v: (
            len([n for n in upstream(f"{SK}.{v}").get("nodes", []) if n["name"] != v]) > 0, ""), 6)

if run("16"):
    print("Fase 16: tabla derivada")
    def derivada():
        r = upstream(f"{SK}.resumen_ventas_cliente")
        srcs = sorted(n["name"] for n in r.get("nodes", []) if n["name"] != "resumen_ventas_cliente")
        cols = sum(len((e.get("lineageDetails") or {}).get("columnsLineage") or []) for e in r.get("upstreamEdges", []))
        return (srcs == ["customer", "payment", "rental"] and cols >= 5, f"orígenes {srcs}, aristas de columna {cols}")
    check("16", "resumen_ventas_cliente con linaje", derivada, 6)

if run("17"):
    print("Fase 17: almacén como segundo servicio")
    check("17", "servicio mysql_dwh", lambda: (
        call("GET", "/services/databaseServices/name/mysql_dwh", ok_missing=True) is not None, ""))

if run("22"):
    print("Fase 22: ETL real y linaje de pipeline")
    check("22", "pipeline etl_sakila_dwh con 2 tareas", lambda: (
        len((call("GET", "/pipelines/name/airflow_etl.etl_sakila_dwh?fields=tasks", ok_missing=True) or {}).get("tasks", [])) == 2, ""), 6)
    check("22", "dim_cliente cargada (599 filas)", lambda: (mysql_count("SELECT COUNT(*) FROM dwh_sakila.dim_cliente") == 599, ""))
    check("22", "fact_pagos cargada (16044 filas)", lambda: (mysql_count("SELECT COUNT(*) FROM dwh_sakila.fact_pagos") == 16044, ""))
    pid = (call("GET", "/pipelines/name/airflow_etl.etl_sakila_dwh", ok_missing=True) or {}).get("id")
    for dst, src in (("dim_cliente", "customer"), ("fact_pagos", "payment")):
        def edge(dst=dst, src=src):
            r = upstream(f"{DWH}.{dst}")
            srcs = [n["fullyQualifiedName"] for n in r.get("nodes", [])]
            via = any(((e.get("lineageDetails") or {}).get("pipeline") or {}).get("id") == pid for e in r.get("upstreamEdges", []))
            return (f"{SK}.{src}" in srcs and via, f"origen {src}, vía pipeline: {via}")
        check("22", f"linaje {src} -> {dst} a través de la pipeline", edge, 6)
    def servicios():
        r = call("GET", "/lineage/getPlatformLineage?view=service")
        return (len(r.get("upstreamEdges", {})) >= 1, f"{len(r.get('upstreamEdges', {}))} aristas entre servicios")
    check("22", "linaje entre servicios", servicios, 6)

if run("uso"):
    print("Fases 18-20: uso de la portada")
    me = call("GET", "/users/name/admin?fields=follows,owns")
    check("18", "admin sigue 10 activos", lambda: (len(me.get("follows", [])) == 10, f"{len(me.get('follows', []))}"))
    pages = call("GET", "/contextCenter/pages?limit=20")["data"]
    check("19", "3 artículos Approved", lambda: (
        len(pages) == 3 and all(p.get("entityStatus") == "Approved" for p in pages), f"{len(pages)} artículos"))
    check("20", "2 KPI", lambda: (len(call("GET", "/kpi")["data"]) == 2, ""))
    def insights():
        r = call("GET", "/apps/name/DataInsightsApplication/status?limit=1", ok_missing=True) or {}
        d = r.get("data", [])
        return (bool(d) and d[0].get("status") == "success", d[0].get("status") if d else "sin ejecuciones")
    check("20", "Data Insights ejecutado", insights, 6)

fails = [r for r in RESULTS if not r[2]]
print(f"\nResumen: {len(RESULTS) - len(fails)} PASS, {len(fails)} FAIL")
sys.exit(1 if fails else 0)
PY
