#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e 'CREATE USER "devuser"@"%" IDENTIFIED BY "DevPass123!";'
docker compose exec mysql mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON appdb.* TO 'devuser'@'%';"