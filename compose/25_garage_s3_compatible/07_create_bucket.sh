#!/bin/bash

docker compose exec garage /garage -c /etc/garage.toml bucket create data-lake
docker compose exec garage /garage -c /etc/garage.toml bucket allow data-lake --key practica --read --write --owner





