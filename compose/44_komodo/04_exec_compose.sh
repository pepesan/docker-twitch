#!/usr/bin/env bash
# Uso: ./04_exec_compose.sh [comando]  (por defecto: sh; servicio: core)
cd "$(dirname "$0")"
docker compose --env-file compose.env exec core "${@:-sh}"
