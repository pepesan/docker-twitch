#!/usr/bin/env bash
set -euo pipefail
container='mariadb-hardened'
for attempt in {1..60}; do
  health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container")
  [[ "$health" == healthy ]] && break
  if [[ "$health" == exited || "$health" == dead ]]; then
    docker logs "$container"
    exit 1
  fi
  sleep 2
done
if [[ "$health" != healthy ]]; then
  echo "MariaDB no pasó a healthy; estado final: $health" >&2
  docker logs "$container"
  exit 1
fi
docker inspect --format 'state={{.State.Status}} health={{.State.Health.Status}} readonly={{.HostConfig.ReadonlyRootfs}} cap-drop={{json .HostConfig.CapDrop}} cap-add={{json .HostConfig.CapAdd}} ports={{json .HostConfig.PortBindings}}' "$container"
docker exec "$container" healthcheck.sh --connect --innodb_initialized
docker exec "$container" sh -c \
  'MYSQL_PWD="$(cat /run/secrets/root_password)" exec mariadb --user=root --batch --skip-column-names -e "SELECT VERSION(), @@local_infile, @@secure_file_priv, @@skip_name_resolve"'
