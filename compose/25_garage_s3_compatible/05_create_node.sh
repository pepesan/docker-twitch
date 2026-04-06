#!/bin/bash
# pilla el ID del comando anterior
ID=8191e2d23c20bdcf
docker compose exec garage /garage -c /etc/garage.toml layout assign $ID -z dc1 -c 1G
docker compose exec garage /garage -c /etc/garage.toml layout apply --version 1
docker compose exec garage /garage -c /etc/garage.toml status




