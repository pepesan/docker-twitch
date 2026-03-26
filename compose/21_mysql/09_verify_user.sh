#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e 'SHOW GRANTS FOR "devuser"@"%";'