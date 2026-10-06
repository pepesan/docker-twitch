#!/usr/bin/env python3
"""Crea por API una regla de alerta de Grafana que dispara siempre (sin
depender de tráfico de error real ni de esperar varios minutos), para
comprobar de punta a punta que el contact point "email-sre" entrega correo
de verdad. Usa un expression "threshold" fijo (1 > 0.5), en la carpeta
"Curso SRE". Sin dependencias externas (usa urllib de la librería estándar).

Uso:
  disparar_alerta_prueba_grafana.py [--host=localhost] [--port=3030] [--user=admin] [--password=...] [--borrar=UID]

Sin --password, la lee de compose.env (GF_SECURITY_ADMIN_PASSWORD).
Con --borrar=UID, borra la regla de prueba en vez de crearla.
"""
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


def main():
    host = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--host=")), "localhost")
    port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--port=")), "3030"))
    user = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--user=")), "admin")
    password = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--password=")), None) or password_de_compose_env()
    borrar = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--borrar=")), None)
    if not password:
        print("No se encontró GF_SECURITY_ADMIN_PASSWORD en compose.env; usa --password=...", file=sys.stderr)
        sys.exit(2)

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
