#!/usr/bin/env python3
"""Comprueba, vía POP3, si han llegado correos al buzón de alertas del
laboratorio (servicio "mailserver", GreenMail). Sin dependencias externas
(usa poplib de la librería estándar).

Uso:
  comprobar_correo_alertas.py [buzon@lab.local] [--host=localhost] [--port=3110] [--borrar]

Por defecto comprueba las dos direcciones usadas en el laboratorio
(alertas-grafana@lab.local y alertas-alertmanager@lab.local). GreenMail no
pide autenticación real: cualquier contraseña vale para el buzón indicado.
"""
import poplib
import sys

BUZONES_POR_DEFECTO = ["alertas-grafana@lab.local", "alertas-alertmanager@lab.local"]


def comprobar(buzon, host, port, borrar):
    print(f"== {buzon} ({host}:{port}) ==")
    try:
        conn = poplib.POP3(host, port, timeout=10)
    except OSError as e:
        print(f"  ERROR conectando: {e}")
        return 1
    try:
        conn.user(buzon)
        conn.pass_("cualquier-cosa")  # GreenMail con auth.disabled no la valida
        n, _tamano_total = conn.stat()
        if n == 0:
            print("  Sin correos.")
            return 0
        print(f"  {n} correo(s):")
        for i in range(1, n + 1):
            _resp, lineas, _oct = conn.retr(i)
            cabeceras = {}
            for raw in lineas:
                linea = raw.decode("utf-8", errors="replace")
                if not linea:
                    break
                if ":" in linea and linea.split(":", 1)[0] in ("From", "To", "Subject", "Date"):
                    clave, valor = linea.split(":", 1)
                    cabeceras[clave] = valor.strip()
            print(f"   #{i} De: {cabeceras.get('From','?')}  Asunto: {cabeceras.get('Subject','?')}  Fecha: {cabeceras.get('Date','?')}")
            if borrar:
                conn.dele(i)
        return 0
    finally:
        conn.quit()


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    host = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--host=")), "localhost")
    port = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--port=")), "3110"))
    borrar = "--borrar" in sys.argv
    buzones = args or BUZONES_POR_DEFECTO
    rc = 0
    for buzon in buzones:
        rc |= comprobar(buzon, host, port, borrar)
    sys.exit(rc)


if __name__ == "__main__":
    main()
