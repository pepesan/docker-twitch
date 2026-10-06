#!/usr/bin/env python3
"""Comprueba cuántos streams de log llegan a Loki por cada agente (Alloy sin
etiqueta "agent", Promtail con agent="promtail"), para confirmar que los dos
están entregando logs de verdad. Sin dependencias externas (usa urllib de la
librería estándar).

Uso:
  comprobar_logs_agentes.py [--host=localhost] [--port=3100] [--rango=5m]
"""
import json
import sys
import urllib.parse
import urllib.request


def main():
    host = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--host=")), "localhost")
    port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--port=")), "3100"))
    rango = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--rango=")), "5m")

    query = f'count by (agent) (count_over_time({{job=~".+"}}[{rango}]))'
    url = f"http://{host}:{port}/loki/api/v1/query?" + urllib.parse.urlencode({"query": query})
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            d = json.load(r)
    except urllib.error.URLError as e:
        print(f"ERROR consultando Loki: {e}", file=sys.stderr)
        sys.exit(1)

    if d.get("status") != "success":
        print(f"Loki respondió sin éxito: {d}", file=sys.stderr)
        sys.exit(1)

    resultados = d["data"]["result"]
    if not resultados:
        print(f"Sin streams en los últimos {rango}.")
        sys.exit(0)

    print(f"status: {d['status']}")
    for r in resultados:
        agent = r["metric"].get("agent", "(sin etiqueta agent, Alloy)")
        print(f"  {agent}: {r['value'][1]} streams")


if __name__ == "__main__":
    main()
