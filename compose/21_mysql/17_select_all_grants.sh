#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e "SELECT * FROM information_schema.user_privileges;"