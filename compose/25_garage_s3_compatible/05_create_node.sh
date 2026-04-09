#!/bin/bash
# pilla el ID del comando anterior
ID=5488b1f66d56ecb1
docker compose exec garage /garage -c /etc/garage.toml layout assign $ID -z dc1 -c 1G
docker compose exec garage /garage -c /etc/garage.toml layout apply --version 1
docker compose exec garage /garage -c /etc/garage.toml status




