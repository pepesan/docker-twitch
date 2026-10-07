#!/usr/bin/env python3
"""Inyecta una alerta sintética directamente en Alertmanager (API v2), sin
esperar a que una regla real la dispare, para comprobar de punta a punta que
el receiver "email-sre" entrega correo de verdad. Sin dependencias externas
(usa urllib de la librería estándar).

Uso:
  disparar_alerta_prueba.py [--host=localhost] [--port=9093] [--alertname=TestEmailAlertmanager]
  disparar_alerta_prueba.py --caida [--servicios=node-exporter,hotrod] [--esperar-resuelta]

Con --caida no se inyecta nada sintético: se PARAN de verdad los servicios
indicados (docker compose stop), se espera a que las reglas reales de
config/alert_rules.yml (InstanceDown, EndpointNoResponde) pasen a "firing" en
Alertmanager y, pase lo que pase (también con Ctrl+C), se vuelven a ARRANCAR
(docker compose start). Con --esperar-resuelta espera además a que las alertas
desaparezcan, es decir, a que llegue el correo [RESOLVED].

Autor: David Vaquero Santiago <pepesan@gmail.com>
"""
import json
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

DIR_COMPOSE = Path(__file__).resolve().parent.parent
# Alerta real de config/alert_rules.yml que provoca la caída de cada servicio.
ALERTA_POR_SERVICIO = {"hotrod": "EndpointNoResponde"}
ALERTA_POR_DEFECTO = "InstanceDown"
TIMEOUT_ESPERA = 180


def alertas_activas(host, port):
    url = f"http://{host}:{port}/api/v2/alerts?active=true"
    with urllib.request.urlopen(url, timeout=10) as r:
        return {a["labels"]["alertname"] for a in json.load(r)}


def esperar(host, port, condicion, descripcion):
    limite = time.time() + TIMEOUT_ESPERA
    while time.time() < limite:
        if condicion(alertas_activas(host, port)):
            return True
        time.sleep(5)
    print(f"  TIMEOUT ({TIMEOUT_ESPERA}s) esperando {descripcion}.", file=sys.stderr)
    return False


def compose(accion, servicios):
    subprocess.run(["docker", "compose", accion, *servicios], cwd=DIR_COMPOSE, check=True)


def simular_caida(host, port, servicios, esperar_resuelta):
    esperadas = {ALERTA_POR_SERVICIO.get(s, ALERTA_POR_DEFECTO) for s in servicios}
    ya_activas = esperadas & alertas_activas(host, port)
    if ya_activas:
        print(f"ERROR: ya están activas {', '.join(sorted(ya_activas))}; no se puede demostrar el disparo. "
              "Restaura los servicios, espera a que se resuelvan y repite.", file=sys.stderr)
        sys.exit(2)
    ok = False
    print(f"Parando {', '.join(servicios)} (alertas esperadas: {', '.join(sorted(esperadas))})...")
    try:
        compose("stop", servicios)
        ok = esperar(host, port, lambda act: esperadas <= act, "las alertas en firing")
        if ok:
            print("  Alertas en firing en Alertmanager.")
    finally:
        print(f"Restaurando {', '.join(servicios)}...")
        compose("start", servicios)
    if esperar_resuelta and ok:
        ok = esperar(host, port, lambda act: not (esperadas & act), "que las alertas se resuelvan")
        if ok:
            print("  Alertas resueltas.")
    print("Comprueba el buzón con:")
    print("  python3 tools/comprobar_correo_alertas.py alertas-alertmanager@lab.local --exigir=FIRING"
          + (" --exigir=RESOLVED" if esperar_resuelta else ""))
    sys.exit(0 if ok else 1)


def main():
    host = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--host=")), "localhost")
    port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--port=")), "9093"))
    alertname = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--alertname=")), "TestEmailAlertmanager")

    if "--caida" in sys.argv:
        servicios = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--servicios=")), "node-exporter,hotrod")
        simular_caida(host, port, servicios.split(","), "--esperar-resuelta" in sys.argv)

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
