#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "${CONFIRM_DOCKER_UNINSTALL:-}" != "YES" ]]; then
  echo "Operación destructiva. Confirma con CONFIRM_DOCKER_UNINSTALL=YES ./02_build.sh" >&2
  exit 1
fi
NAME="$(basename "$PWD")"
../../scripts/build_job.sh "$NAME" 'CONFIRM_DATA_LOSS=true'
