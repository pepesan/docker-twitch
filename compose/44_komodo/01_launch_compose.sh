#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose --env-file compose.env up -d

echo "URL: http://localhost:9120/"
