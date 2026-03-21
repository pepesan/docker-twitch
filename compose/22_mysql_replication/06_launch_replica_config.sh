#!/bin/bash

set -e

docker cp setup_replica.sql mysql-replica:/setup_replica.sql
docker compose exec -T mysql-replica mysql -u root -proot < setup_replica.sql

