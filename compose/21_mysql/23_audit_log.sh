#!/bin/bash

set -e


docker compose exec mysql mysql -uroot -proot -e "SET GLOBAL general_log_file = '/var/lib/mysql/general.log';"
docker compose exec mysql mysql -uroot -proot -e "SHOW VARIABLES LIKE 'general_log_file';"
docker compose exec mysql mysql -uroot -proot -e "SET GLOBAL general_log = 'ON';"
docker compose exec mysql cat /var/lib/mysql/general.log
