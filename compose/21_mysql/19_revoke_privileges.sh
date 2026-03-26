#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e 'REVOKE SELECT ON appdb.usuarios FROM '\''readonly_user'\''@'\''%'\'';'