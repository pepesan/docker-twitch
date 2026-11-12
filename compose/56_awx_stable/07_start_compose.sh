#!/usr/bin/env bash
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose start

echo "URL: https://localhost:${AWX_HTTPS_PORT}/"
echo "Login: admin / ${AWX_ADMIN_PASSWORD:-<ver secrets.env>}"
