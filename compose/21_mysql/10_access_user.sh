#!/bin/bash

set -e

docker compose exec mysql mysql -udevuser -pDevPass123! appdb -e "SHOW TABLES;"