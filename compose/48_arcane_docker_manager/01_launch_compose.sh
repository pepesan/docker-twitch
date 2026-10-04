#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d

echo "URL: http://localhost:3552/"
echo "Login: arcane"
echo "Password: arcane-admin"

