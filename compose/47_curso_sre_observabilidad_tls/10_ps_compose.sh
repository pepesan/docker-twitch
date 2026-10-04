#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose --env-file compose.env ps
