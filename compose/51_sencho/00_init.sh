#!/usr/bin/env bash
# Crea las carpetas de datos (./data) y de stacks (./stacks) de Sencho.
# Ejecutar una vez antes del primer 01_launch_compose.sh y tras 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p data stacks
