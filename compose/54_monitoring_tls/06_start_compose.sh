#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
docker compose --env-file ../53_monitoring/.env -f ../53_monitoring/compose.yaml -f compose.tls.yaml start
