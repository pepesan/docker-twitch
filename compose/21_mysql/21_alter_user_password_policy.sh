#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e "ALTER USER 'devuser'@'%' PASSWORD EXPIRE INTERVAL 90 DAY;"