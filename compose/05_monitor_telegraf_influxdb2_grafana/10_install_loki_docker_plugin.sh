#!/bin/bash

# Instalación del Driver log de Loki para Docker
# Ref: https://grafana.com/docs/loki/latest/send-data/docker-driver/
docker plugin install grafana/loki-docker-driver:2.9.2 \
  --alias loki --grant-all-permissions

# Listar los plugins
docker plugin ls

