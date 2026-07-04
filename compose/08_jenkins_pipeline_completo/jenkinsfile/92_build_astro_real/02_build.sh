#!/bin/bash
# Lanza y espera el build de este job
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/build_job.sh "$NAME"
