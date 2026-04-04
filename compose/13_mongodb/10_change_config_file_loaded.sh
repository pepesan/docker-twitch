#!/bin/bash

# Cambiar config en compose
sed -i 's|mongod.conf:/etc/mongod.conf|mongod.conf.auth:/etc/mongod.conf|g' compose.yaml

# Reiniciar contenedor
docker compose down
docker compose up -d

