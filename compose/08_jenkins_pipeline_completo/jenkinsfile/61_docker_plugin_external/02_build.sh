#!/bin/bash
# Lanza la compilación en Jenkins y espera el resultado
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/build_job.sh "$NAME"
