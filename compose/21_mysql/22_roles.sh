#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e "CREATE ROLE 'readonly_role';"
docker compose exec mysql mysql -uroot -proot -e "GRANT SELECT ON appdb.* TO 'readonly_role';"
docker compose exec mysql mysql -uroot -proot -e "GRANT 'readonly_role' TO 'readonly_user'@'%';"
docker compose exec mysql mysql -uroot -proot -e "SET DEFAULT ROLE 'readonly_role' TO 'readonly_user'@'%';"
docker compose exec mysql mysql -uroot -proot -e "SHOW GRANTS FOR 'readonly_user'@'%';"