#!/bin/bash
# Da de alta (o actualiza) este job en Jenkins
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/create_job.sh "$NAME"
