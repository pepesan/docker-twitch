#!/bin/bash
# Muestra el estado de los contenedores del stack
set -e
cd "$(dirname "$0")"
docker compose -p jenkins_docker_pipeline ps
