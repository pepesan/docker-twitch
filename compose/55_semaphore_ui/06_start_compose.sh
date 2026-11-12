#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source scripts/lib_compose.sh
docker compose config -q
docker compose up -d
