#!/usr/bin/env bash
# Crea la carpeta de datos persistentes ./data. Ejecutar una vez antes del
# primer 01_launch_compose.sh y cada vez que se borre con 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p data
