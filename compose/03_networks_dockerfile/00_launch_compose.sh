#!/usr/bin/env bash
# Create a custom Docker network named 'red_ping'
docker network create red_ping
# Launch the Docker Compose services in detached mode
docker compose up -d

