#!/usr/bin/env python3
"""Inyecta una alerta sintética directamente en Alertmanager (API v2), sin
esperar a que una regla real la dispare, para comprobar de punta a punta que
el receiver "email-sre" entrega correo de verdad. Sin dependencias externas
(usa urllib de la librería estándar).

Uso:
  disparar_alerta_prueba.py [--host=localhost] [--port=9093] [--alertname=TestEmailAlertmanager]
"""
import json
import sys
import urllib.request
from datetime import datetime, timezone


def main():
    host = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--host=")), "localhost")
    port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--port=")), "9093"))
    alertname = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--alertname=")), "TestEmailAlertmanager")

    payload = [
        {
            "labels": {"alertname": alertname, "severity": "critical"},
            "annotations": {"summary": "Prueba de envío de email desde Alertmanager"},
            "startsAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        }
    ]
    url = f"http://{host}:{port}/api/v2/alerts"
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(), headers={"Content-Type": "application/json"}, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            print(f"Alerta '{alertname}' inyectada en {url} (HTTP {r.status}).")
    except urllib.error.URLError as e:
        print(f"ERROR inyectando la alerta: {e}", file=sys.stderr)
        sys.exit(1)
    print("Espera group_wait (10s por defecto en config/alertmanager.yml) y comprueba el buzón con:")
    print("  python3 tools/comprobar_correo_alertas.py alertas-alertmanager@lab.local")


if __name__ == "__main__":
    main()
