#!/bin/bash
# Borra todos los jobs dados de alta en Jenkins (reset "blando", sin
# parar el controller). Para un reset completo usar 100_destroy.sh
set -e
cd "$(dirname "$0")"
./scripts/delete_all_jobs.sh

echo "Jobs borrados. El controller (y el agente, si estaba levantado) siguen"
echo "corriendo — comprueba con ./02_ps.sh."
