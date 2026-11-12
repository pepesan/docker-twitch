#!/usr/bin/env bash
cd "$(dirname "$0")"
AWX_EXAMPLE_DIR="$(pwd)"
export AWX_EXAMPLE_DIR
source scripts/lib_load_env.sh
docker compose ps
