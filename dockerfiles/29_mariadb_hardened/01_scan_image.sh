#!/usr/bin/env bash
set -euo pipefail
image='docker-twitch-mariadb-hardened:11.8.9-1'
if ! command -v trivy >/dev/null 2>&1; then
  echo 'Falta Trivy: instala Trivy para escanear la imagen antes de ejecutarla.' >&2
  exit 127
fi
docker image inspect "$image" >/dev/null 2>&1 || {
  echo "No existe $image; ejecuta 00_create_image.sh primero." >&2
  exit 1
}
trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 "$image"
