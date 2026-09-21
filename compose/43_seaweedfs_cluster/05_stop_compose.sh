#!/usr/bin/env bash
# Uso: ./05_stop_compose.sh [servicio ...]  (sin argumentos: para todos)
cd "$(dirname "$0")"
docker compose stop "$@"
