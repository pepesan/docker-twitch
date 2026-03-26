#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e '
CREATE USER '\''readonly_user'\''@'\''%'\'' IDENTIFIED BY '\''ReadOnly123!'\'';
GRANT SELECT ON appdb.usuarios TO '\''readonly_user'\''@'\''%'\'';
FLUSH PRIVILEGES;'