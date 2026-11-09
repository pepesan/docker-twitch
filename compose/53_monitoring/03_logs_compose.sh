#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if (($#)); then
  docker compose logs -f "$@"
else
  docker compose logs -f
fi
