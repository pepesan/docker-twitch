#!/bin/bash

docker compose exec garage /garage -c /etc/garage.toml bucket info data-lake
docker compose exec garage /garage -c /etc/garage.toml key info practica





