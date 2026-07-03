#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

docker compose up -d

echo ""
echo "==> web disponible en: http://localhost:8080"
echo "==> Para levantar también el servicio opcional: docker compose --profile monitoring up -d"
