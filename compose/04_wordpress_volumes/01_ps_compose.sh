#!/usr/bin/env bash
# Check the status of the Docker Compose services
docker compose ps
# List the Docker volumes to verify that the WordPress data volume has been created
docker volume ls | grep wp


