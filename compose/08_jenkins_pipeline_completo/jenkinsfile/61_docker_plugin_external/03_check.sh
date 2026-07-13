#!/bin/bash
# Consulta el estado y log de la última ejecución del job en Jenkins
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/check_job.sh "$NAME"
