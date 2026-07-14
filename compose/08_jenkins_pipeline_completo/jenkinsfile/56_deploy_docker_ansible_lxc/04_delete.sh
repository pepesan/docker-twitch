#!/bin/bash
# Elimina este job de Jenkins
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/delete_job.sh "$NAME"
