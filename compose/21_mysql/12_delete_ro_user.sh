#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e '
DROP USER '\''readonly_user'\''@'\''%'\'';
'