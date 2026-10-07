#!/usr/bin/env python3
"""Crea por API una regla de alerta de Grafana que dispara siempre (sin
depender de tráfico de error real ni de esperar varios minutos), para
comprobar de punta a punta que el contact point "email-sre" entrega correo
de verdad. Usa un expression "threshold" fijo (1 > 0.5), en la carpeta
"Curso SRE". Sin dependencias externas (usa urllib de la librería estándar).

Uso:
  disparar_alerta_prueba_grafana.py [--host=localhost] [--port=3030] [--user=admin] [--password=...] [--borrar=UID]
  disparar_alerta_prueba_grafana.py --fallo [--probabilidad=0.9] [--duracion=240] [--app-port=8090]

Sin --password, la lee de compose.env (GF_SECURITY_ADMIN_PASSWORD).
Con --borrar=UID, borra la regla de prueba en vez de crearla.

Con --fallo no se crea ninguna regla sintética: se genera tráfico real contra
/api/fallo?probabilidad=P de demo-app (HTTP 500 a propósito) para que dispare
la regla ya provisionada "DemoAppHighErrorRate (Grafana)" (config/grafana/
provisioning/alerting/rules.yaml, for: 1m, intervalo 1m). Consulta el estado de
la regla hasta que pasa a "firing" (o se agota --duracion) y sale con 0 si
llegó a dispararse.
"""
import time
import base64
import json
import re
import sys
import urllib.error
import urllib.request


def password_de_compose_env():
    try:
        with open("compose.env") as f:
            m = re.search(r"^GF_SECURITY_ADMIN_PASSWORD=(.+)$", f.read(), re.M)
            if m:
                return m.group(1).strip()
    except OSError:
        pass
    return None


def llamar(host, port, user, password, method, path, body=None):
    url = f"http://{host}:{port}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={"Content-Type": "application/json"})
    auth = base64.b64encode(f"{user}:{password}".encode()).decode()
    req.add_header("Authorization", f"Basic {auth}")
    if body is not None:
        req.add_header("X-Disable-Provenance", "true")
    with urllib.request.urlopen(req, timeout=15) as r:
        contenido = r.read()
        return r.status, (json.loads(contenido) if contenido else None)


def carpeta_curso_sre(host, port, user, password):
    _status, folders = llamar(host, port, user, password, "GET", "/api/folders")
    for f in folders:
        if f.get("title") == "Curso SRE":
            return f["uid"]
    raise RuntimeError('No se encontró la carpeta "Curso SRE".')


REGLA_REAL = "DemoAppHighErrorRate (Grafana)"


def estado_regla(host, port, user, password, titulo):
    _s, datos = llamar(host, port, user, password, "GET", "/api/prometheus/grafana/api/v1/rules")
    for g in datos["data"]["groups"]:
        for r in g["rules"]:
            if r["name"] == titulo:
                return r["state"]
    return None


def disparar_con_fallos(host, port, user, password, app_port, probabilidad, duracion):
    url = f"http://{host}:{app_port}/api/fallo?probabilidad={probabilidad}"
    print(f"Generando tráfico real a {url} durante hasta {duracion}s (regla: {REGLA_REAL})...")
    fin = time.time() + duracion
    peticiones = fallos = 0
    ultimo = None
    while time.time() < fin:
        try:
            with urllib.request.urlopen(url, timeout=10) as r:
                codigo = r.status
        except urllib.error.HTTPError as e:
            codigo = e.code
        peticiones += 1
        fallos += codigo >= 500
        estado = estado_regla(host, port, user, password, REGLA_REAL)
        if estado != ultimo:
            print(f"  [{peticiones} peticiones, {fallos} con 5xx] estado de la regla: {estado}")
            ultimo = estado
        if estado == "firing":
            print("Regla en firing: Grafana enviará el correo al contact point email-sre.")
            print("Comprueba el buzón con:")
            print("  python3 tools/comprobar_correo_alertas.py alertas-grafana@lab.local --exigir=FIRING")
            return 0
        time.sleep(0.5)
    print(f"TIMEOUT: la regla no llegó a firing ({peticiones} peticiones, {fallos} con 5xx).", file=sys.stderr)
    return 1


def main():
    host = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--host=")), "localhost")
    port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--port=")), "3030"))
    user = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--user=")), "admin")
    password = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--password=")), None) or password_de_compose_env()
    borrar = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--borrar=")), None)
    if not password:
        print("No se encontró GF_SECURITY_ADMIN_PASSWORD en compose.env; usa --password=...", file=sys.stderr)
        sys.exit(2)

    if "--fallo" in sys.argv:
        probabilidad = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--probabilidad=")), "0.9")
        duracion = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--duracion=")), "240"))
        app_port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--app-port=")), "8090"))
        try:
            sys.exit(disparar_con_fallos(host, port, user, password, app_port, probabilidad, duracion))
        except urllib.error.HTTPError as e:
            print(f"ERROR HTTP {e.code}: {e.read().decode()[:300]}", file=sys.stderr)
            sys.exit(1)

    try:
        if borrar:
            llamar(host, port, user, password, "DELETE", f"/api/v1/provisioning/alert-rules/{borrar}")
            print(f"Regla {borrar} borrada.")
            return
        folder_uid = carpeta_curso_sre(host, port, user, password)
        payload = {
            "title": "PruebaEmailGrafana",
            "ruleGroup": "prueba-email",
            "folderUID": folder_uid,
            "condition": "C",
            "data": [
                {"refId": "A", "relativeTimeRange": {"from": 60, "to": 0}, "datasourceUid": "__expr__",
                 "model": {"type": "math", "expression": "1", "refId": "A"}},
                {"refId": "C", "datasourceUid": "__expr__",
                 "model": {"type": "threshold", "expression": "A",
                           "conditions": [{"evaluator": {"type": "gt", "params": [0.5]}}], "refId": "C"}},
            ],
            "noDataState": "OK",
            "execErrState": "Error",
            "for": "0s",
            "labels": {"severity": "critical"},
            "annotations": {"summary": "Prueba real de notificación por email desde Grafana"},
        }
        _status, regla = llamar(host, port, user, password, "POST", "/api/v1/provisioning/alert-rules", payload)
        print(f"Regla '{regla['title']}' creada (uid={regla['uid']}).")
        print("Espera a la siguiente evaluación del grupo y comprueba el buzón con:")
        print("  python3 tools/comprobar_correo_alertas.py alertas-grafana@lab.local")
        print(f"Para borrarla después: python3 tools/disparar_alerta_prueba_grafana.py --borrar={regla['uid']}")
    except urllib.error.HTTPError as e:
        print(f"ERROR HTTP {e.code}: {e.read().decode()[:300]}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
