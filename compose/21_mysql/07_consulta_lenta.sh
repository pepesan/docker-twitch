#!/bin/bash

set -e

docker compose exec mysql mysql -u root -proot -e 'SELECT SLEEP(11), "Probando el slow log";'

docker compose exec mysql cat /var/lib/mysql/slow-queries.log

sudo mysqldumpslow ./data/slow-queries.log