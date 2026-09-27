#!/usr/bin/env bash
# Uso: ./04_exec_compose.sh [comando]  (por defecto: sh; único servicio: dockhand)
cd "$(dirname "$0")"
docker compose exec dockhand "${@:-sh}"
