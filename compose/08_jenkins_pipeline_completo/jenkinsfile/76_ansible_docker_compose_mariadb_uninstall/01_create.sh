#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NAME="$(basename "$PWD")"
../../scripts/create_job.sh "$NAME"
