#!/usr/bin/env bash
# Ejecuta los scripts de uso, que pueblan los widgets de la portada.
set -euo pipefail
cd "$(dirname "$0")"

for fase in 18_uso_activos_seguidos.sh 19_uso_centro_contexto.sh 20_uso_kpi_insights.sh; do
  ./"$fase"
done
