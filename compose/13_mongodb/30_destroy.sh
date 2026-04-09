#!/bin/bash


docker compose down

sudo rm -rf data
sudo rm -rf logs

# Volver a config sin auth
sed -i 's|mongod.conf.auth:/etc/mongod.conf|mongod.conf:/etc/mongod.conf|g' compose.yaml
