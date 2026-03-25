#!/bin/bash

set -e
docker compose exec mysql-replica mysql -u root -proot -e "SHOW REPLICA STATUS\G" | grep Replica
docker compose exec mysql-replica mysql -u root -proot -e "SHOW REPLICA STATUS\G" | grep Auto

