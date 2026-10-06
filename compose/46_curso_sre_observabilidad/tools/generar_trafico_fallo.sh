#!/bin/bash
# Genera tráfico real y continuo contra /api/fallo de demo-app-sre (Compose 46),
# para disparar de verdad la regla DemoAppHighErrorRate en Grafana
# (for: 2m) y tener una traza con status=500 que localizar en Tempo.
#
# Uso:
#   tools/generar_trafico_fallo.sh [probabilidad] [duracion_segundos]
#
# Por defecto: probabilidad=0.9, duracion_segundos=180 (3 minutos, suficiente
# para que la regla pase inactive -> pending -> firing con for: 2m).
set -euo pipefail

PROBABILIDAD="${1:-0.9}"
DURACION="${2:-180}"
HOST="${HOST:-localhost}"
PUERTO="${PUERTO:-8090}"
URL="http://${HOST}:${PUERTO}/api/fallo?probabilidad=${PROBABILIDAD}"

echo "Generando tráfico a ${URL} durante ${DURACION}s..."
fin=$(( $(date +%s) + DURACION ))
peticiones=0
fallos=0
while [ "$(date +%s)" -lt "$fin" ]; do
  codigo=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  peticiones=$((peticiones + 1))
  [ "$codigo" = "500" ] && fallos=$((fallos + 1))
  sleep 1
done
echo "Hecho: ${peticiones} peticiones, ${fallos} con status 500."
