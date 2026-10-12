#!/usr/bin/env bash
# Ejecuta todas las fases de gobierno del dato sobre Sakila, en orden.
set -euo pipefail
cd "$(dirname "$0")"

for fase in 09_gobierno_documentacion.sh 10_gobierno_clasificacion.sh \
            11_gobierno_glosario.sh 12_gobierno_propiedad.sh 13_gobierno_calidad.sh \
            15_gobierno_linaje_vistas.sh 16_gobierno_linaje_derivada.sh \
            17_gobierno_almacen_servicio.sh 22_gobierno_linaje_etl.sh; do
  ./"$fase"
done
