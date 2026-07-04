#!/bin/bash
# Muestra los logs del Jenkins controller (Ctrl+C para salir)
set -e
cd "$(dirname "$0")"
docker compose -p jenkins_docker_pipeline logs -f
