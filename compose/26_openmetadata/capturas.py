#!/usr/bin/env python3
"""Genera las capturas de pantalla del laboratorio con un Chrome real (Playwright).

Cada captura se guarda en capturas/ con el nombre MÓDULO-PASO-descripcion.png, de forma
que el orden alfabético sea el orden del laboratorio y el README pueda referenciarlas.
Requiere el laboratorio levantado y poblado (./90_e2e.sh o las fases en orden) y:
    pip install playwright   (se usa el Chrome instalado en el sistema)
Uso: python3 capturas.py [fragmento_de_nombre ...]
"""
import os
import re
import sys
import urllib.parse

from playwright.sync_api import sync_playwright

OM = os.environ.get("OPENMETADATA_URL", "http://localhost:8585")
AF = os.environ.get("AIRFLOW_URL", "http://localhost:8080")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "capturas")
SK = "mysql_sakila.default.sakila"

# (fichero, app, ruta, pestaña a pulsar o None)
SHOTS = [
    # Módulo 0 y 2: acceso y primer catálogo
    ("00-01-login-openmetadata.png", "om", "/signin", None, "anon"),
    ("00-02-login-airflow.png", "af", "/auth/login", None, "anon"),
    ("00-03-portada-openmetadata.png", "om", "/my-data", None, None),
    ("02-01-servicios-bases-de-datos.png", "om", "/settings/services/databases", None, None),
    ("02-02-servicio-mysql-agentes.png", "om", "/service/databaseServices/mysql_openmetadata", "Agentes", None),
    ("02-04-agregar-servicio-asistente.png", "om", "/settings/services/databases", "Añadir nuevo Servicio", None),
    ("02-03-tabla-clientes-columnas.png", "om", "/table/mysql_openmetadata.default.openmetadata_db.clientes", None, None),
    # Módulo 3: Sakila
    ("03-01-explorar-arbol-bases-de-datos.png", "om", "/explore/tables", None, None),
    ("03-02-sakila-tabla-customer.png", "om", f"/table/{SK}.customer", None, None),
    ("03-03-sakila-vista-customer-list.png", "om", f"/table/{SK}.customer_list", None, None),
    # Módulos 4 a 7: gobierno
    ("04-01-documentacion-columnas-customer.png", "om", f"/table/{SK}.customer", None, None),
    ("05-01-clasificacion-pii-columnas-customer.png", "om", f"/table/{SK}.customer", None, None),
    ("05-02-clasificacion-etiquetas-pii.png", "om", "/tags", "PII", None),
    ("06-01-glosario-sakila.png", "om", "/glossary/GlosarioSakila", None, None),
    ("06-02-glosario-termino-cliente.png", "om", "/glossary/GlosarioSakila.Cliente", None, None),
    ("07-01-dominios.png", "om", "/domain", None, None),
    ("07-02-equipo-comercial.png", "om", "/settings/members/teams/EquipoComercial", None, None),
    # Módulo 8: calidad
    ("08-01-tests-de-calidad-resumen.png", "om", "/data-quality/test-cases", None, None),
    ("08-02-tests-de-calidad-casos-de-prueba.png", "om", "/data-quality/test-cases", "Casos de Prueba", None),
    ("08-04-anadir-caso-de-prueba.png", "om", "/data-quality/test-cases", "Añadir Caso de Prueba", None),
    ("08-03-tabla-customer-observabilidad.png", "om", f"/table/{SK}.customer", "Observabilidad", None),
    # Módulo 9: linaje
    ("09-01-linaje-vista-customer-list.png", "om", f"/table/{SK}.customer_list", "Linaje", None),
    ("09-02-linaje-tabla-derivada-resumen-ventas.png", "om", f"/table/{SK}.resumen_ventas_cliente", "Linaje", None),
    ("09-03-linaje-almacen-dim-cliente.png", "om", "/table/mysql_dwh.default.dwh_sakila.dim_cliente", "Linaje", None),
    ("09-04-linaje-servicios.png", "om", "/lineage", None, None),
    ("09-05-pipeline-etl-tareas.png", "om", "/pipeline/airflow_etl.etl_sakila_dwh", None, None),
    ("09-06-pipeline-etl-ejecuciones.png", "om", "/pipeline/airflow_etl.etl_sakila_dwh", "Ejecuciones", None),
    # Módulo 10: uso
    ("10-01-portada-completa.png", "om", "/my-data", None, None),
    ("10-02-centro-de-contexto-resumen.png", "om", "/context-center/overview", None, None),
    ("10-03-centro-de-contexto-articulos.png", "om", "/context-center/articles", None, None),
    ("10-04-perspectivas-kpi.png", "om", "/data-insights/kpi", None, None),
    ("10-05-perspectivas-activos-de-datos.png", "om", "/data-insights/data-assets", None, None),
    ("10-06-aplicaciones.png", "om", "/settings/apps", None, None),
    # Módulo 11: Airflow
    ("11-01-airflow-lista-de-dags.png", "af", "/dags", None, None),
    ("11-02-airflow-dag-etl-resumen.png", "af", "/dags/etl_sakila_dwh", None, None),
    ("11-03-airflow-dag-etl-ejecuciones.png", "af", "/dags/etl_sakila_dwh/runs", None, None),
    ("11-04-airflow-dag-etl-tareas.png", "af", "/dags/etl_sakila_dwh/tasks", None, None),
    ("11-05-airflow-dag-etl-codigo.png", "af", "/dags/etl_sakila_dwh/code", None, None),
    ("11-06-airflow-dag-calidad-customer.png", "af", "/dags/customer_calidad", None, None),
    ("11-07-airflow-dag-lineaje-vistas.png", "af", "/dags/mysql_sakila_lineage", None, None),
    ("11-08-airflow-ejecucion-tareas.png", "af", "/dags/etl_sakila_dwh/runs/{RUN}", None, None),
    ("11-09-airflow-log-tarea-carga-dim-cliente.png", "af", "/dags/etl_sakila_dwh/runs/{RUN}/tasks/carga_dim_cliente", None, None),
    ("11-10-airflow-log-tarea-carga-fact-pagos.png", "af", "/dags/etl_sakila_dwh/runs/{RUN}/tasks/carga_fact_pagos", None, None),
]


def login_om(page):
    page.goto(OM, wait_until="domcontentloaded")
    page.wait_for_selector('input[type="password"]', timeout=20000)
    page.fill('input[type="text"], input[id="email"]', "admin@open-metadata.org")
    page.fill('input[type="password"]', "admin")
    page.click('button[type="submit"]')
    page.wait_for_timeout(4000)


def login_af(page):
    page.goto(AF, wait_until="domcontentloaded")
    page.wait_for_selector('input[type="password"]', timeout=20000)
    page.fill('input[name="username"], input[type="text"]', "admin")
    page.fill('input[type="password"]', "admin")
    page.click('button[type="submit"]')
    page.wait_for_timeout(4000)


def latest_run():
    """Última ejecución correcta del DAG etl_sakila_dwh (para construir rutas con {RUN})."""
    import json
    import urllib.request

    def call(path, body=None):
        r = urllib.request.Request(AF + path, method="POST" if body else "GET")
        if body:
            r.add_header("Content-Type", "application/json")
        if call.tok:
            r.add_header("Authorization", "Bearer " + call.tok)
        return json.loads(urllib.request.urlopen(r, json.dumps(body).encode() if body else None, timeout=20).read())

    call.tok = None
    call.tok = call("/auth/token", {"username": "admin", "password": "admin"})["access_token"]
    runs = call("/api/v2/dags/etl_sakila_dwh/dagRuns?limit=20&order_by=-start_date")["dag_runs"]
    ok = [r for r in runs if r["state"] == "success"]
    return (ok or runs)[0]["dag_run_id"] if runs else ""


def close_toasts(page):
    for sel in ['.ant-notification-notice-close', 'button[aria-label="Close"]', '[data-testid="close-notification"]']:
        try:
            for el in page.locator(sel).all():
                el.click(timeout=800)
        except Exception:
            pass


def main():
    only = sys.argv[1:]
    try:
        run_id = latest_run()
    except Exception:  # noqa: BLE001
        run_id = ""
    os.makedirs(OUT, exist_ok=True)
    done, failed = [], []
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        ctx_args = dict(viewport={"width": 1440, "height": 900}, locale="es-ES")
        sessions = {}
        for app, login in (("om", login_om), ("af", login_af)):
            ctx = browser.new_context(**ctx_args)
            pg = ctx.new_page()
            login(pg)
            sessions[app] = pg
        anon = {a: browser.new_context(**ctx_args).new_page() for a in ("om", "af")}

        for name, app, path, tab, mode in SHOTS:
            if only and not any(o in name for o in only):
                continue
            page = anon[app] if mode == "anon" else sessions[app]
            base = OM if app == "om" else AF
            path = path.replace("{RUN}", urllib.parse.quote(run_id))
            try:
                page.goto(base + path, wait_until="domcontentloaded", timeout=45000)
                page.wait_for_timeout(3500)
                if tab:
                    tabs = page.locator(f'[role="tab"]:has-text("{tab}")')
                    # primero pestañas reales (no el menú lateral); si no hay, el texto exacto en el contenido
                    buttons = page.get_by_role("button", name=re.compile(re.escape(tab), re.I))
                    if tabs.count():
                        target = tabs.first
                    elif buttons.count():
                        target = buttons.first
                    else:
                        target = page.get_by_text(tab, exact=True).first
                    target.click(timeout=8000)
                    page.wait_for_timeout(3000)
                close_toasts(page)
                if app == "om" and mode != "anon" and "/signin" in page.url:
                    raise RuntimeError("redirigido al login")
                page.screenshot(path=os.path.join(OUT, name))
                done.append(name)
            except Exception as e:  # noqa: BLE001
                failed.append((name, f"{type(e).__name__}: {str(e)[:80]}"))
        browser.close()
    print(f"Capturas hechas: {len(done)}")
    for name, why in failed:
        print(f"  FALLO {name}: {why}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
