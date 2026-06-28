#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[ -f .env ] && source .env
HTTP_PORT="${HTTP_PORT:-3000}"
SSH_PORT="${SSH_PORT:-222}"

docker compose up -d

echo ""
echo "==> Forgejo disponible en:  http://localhost:${HTTP_PORT}"
echo "==> SSH git disponible en:  ssh://localhost:${SSH_PORT}"
