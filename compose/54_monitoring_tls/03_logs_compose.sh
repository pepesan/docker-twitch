#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
compose=(docker compose --env-file ../53_monitoring/.env -f ../53_monitoring/compose.yaml -f compose.tls.yaml)
if (($#)); then
  "${compose[@]}" logs -f "$@"
else
  "${compose[@]}" logs -f
fi
