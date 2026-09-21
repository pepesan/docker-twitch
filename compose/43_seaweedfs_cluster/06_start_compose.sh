#!/usr/bin/env bash
# Uso: ./06_start_compose.sh [servicio ...]  (sin argumentos: arranca todos)
cd "$(dirname "$0")"
docker compose start "$@"
