#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
./00_init.sh
docker compose config -q
docker compose up -d
docker compose ps
