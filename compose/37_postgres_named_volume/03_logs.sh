#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Uso: ./03_logs.sh [servicio]   ejemplo: ./03_logs.sh db
docker compose logs -f "$@"
