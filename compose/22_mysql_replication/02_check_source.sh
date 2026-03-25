#!/bin/bash

set -e

docker compose exec mysql-source mysql -u root -proot

# entrando desde localhost
# mysql -h 127.0.0.1 -P 3307 -u root -proot


