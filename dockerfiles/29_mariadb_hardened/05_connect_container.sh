#!/usr/bin/env bash
set -euo pipefail
docker exec -it mariadb-hardened mariadb --host=127.0.0.1 --user=app --password example
