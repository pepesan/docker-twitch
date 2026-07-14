#!/bin/bash
# Lanza y espera el build de este job
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/build_job.sh "$NAME"

echo
echo "========================================================================"
echo "Análisis de SonarQube completado con éxito."
echo "Puedes ver los resultados en:"
echo "  http://localhost:9005/dashboard?id=com.cursosdedesarrollo:demo-maven"
echo "========================================================================"
echo
