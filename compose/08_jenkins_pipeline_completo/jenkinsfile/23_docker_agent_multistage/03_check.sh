#!/bin/bash
# Comprueba el último build de este job en Jenkins y muestra su log completo
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/check_job.sh "$NAME"
