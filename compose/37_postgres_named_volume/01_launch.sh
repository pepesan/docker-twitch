#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

docker compose up -d

echo ""
echo "==> Postgres disponible en: localhost:5432 (db appdb, user appuser)"
