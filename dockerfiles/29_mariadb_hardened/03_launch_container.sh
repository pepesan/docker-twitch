#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
image='docker-twitch-mariadb-hardened:11.8.9-1'
container='mariadb-hardened'
docker image inspect "$image" >/dev/null 2>&1 || {
  echo "No existe $image; ejecuta 00_create_image.sh primero." >&2
  exit 1
}
for secret in secrets/root_password secrets/app_password; do
  [[ -r "$secret" ]] || { echo "Falta $secret; ejecuta 02_init_secrets.sh." >&2; exit 1; }
done
if docker container inspect "$container" >/dev/null 2>&1; then
  echo "El contenedor $container ya existe; usa 04_check_container.sh o 08_delete_container.sh." >&2
  exit 1
fi
docker volume create mariadb_hardened_data >/dev/null
docker run --detach \
  --name "$container" \
  --restart unless-stopped \
  --publish 127.0.0.1:3307:3306 \
  --mount type=volume,src=mariadb_hardened_data,dst=/var/lib/mysql \
  --mount "type=bind,src=$PWD/secrets/root_password,dst=/run/secrets/root_password,readonly" \
  --mount "type=bind,src=$PWD/secrets/app_password,dst=/run/secrets/app_password,readonly" \
  --tmpfs /run/mysqld:rw,noexec,nosuid,nodev,size=16m,uid=999,gid=999,mode=0750 \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m \
  --read-only \
  --cap-drop ALL \
  --cap-add CHOWN \
  --cap-add SETUID \
  --cap-add SETGID \
  --cap-add DAC_READ_SEARCH \
  --security-opt no-new-privileges:true \
  --pids-limit 256 \
  --env MARIADB_ROOT_PASSWORD_FILE=/run/secrets/root_password \
  --env MARIADB_DATABASE=example \
  --env MARIADB_USER=app \
  --env MARIADB_PASSWORD_FILE=/run/secrets/app_password \
  "$image"
