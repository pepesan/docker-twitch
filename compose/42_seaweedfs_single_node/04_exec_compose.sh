#!/usr/bin/env bash
# Uso: ./04_exec_compose.sh [comando]  (por defecto: sh; único servicio: seaweedfs)
cd "$(dirname "$0")"
docker compose exec seaweedfs "${@:-sh}"
