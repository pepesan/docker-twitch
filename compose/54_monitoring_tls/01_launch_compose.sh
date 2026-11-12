#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
./00_init.sh
compose=(docker compose --env-file ../53_monitoring/.env -f ../53_monitoring/compose.yaml -f compose.tls.yaml)
"${compose[@]}" config -q
"${compose[@]}" up -d
"${compose[@]}" ps
