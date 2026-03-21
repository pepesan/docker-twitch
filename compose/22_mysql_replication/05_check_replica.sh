#!/bin/bash

set -e

docker compose exec mysql-replica mysql -u root -proot

