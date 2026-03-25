#!/bin/bash

set -e
docker compose exec mysql-source mysql -u root -proot -e "
USE appdb;
INSERT INTO items (name) VALUES ('prueba final');
SELECT * FROM items;
"

